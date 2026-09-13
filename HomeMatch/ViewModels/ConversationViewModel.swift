import Foundation
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published private(set) var messages: [Message]
    @Published var draft = ""
    @Published private(set) var sendError: InitiateRoommateContactError?
    /// True while sending is paused after a rate-limit error (spec: "temporarily disable send button").
    @Published private(set) var isSendTemporarilyDisabled = false

    let currentUserID: String
    let recipientID: String

    private let useCase: InitiateRoommateContactUseCase
    private let now: () -> Date
    private var cooldownTask: Task<Void, Never>?

    private static let rateLimitCooldown: Duration = .seconds(10)

    init(
        recipientID: String,
        matchPercentage: Int,
        currentUserID: String = ConversationViewModel.sampleCurrentUserID,
        messages: [Message]? = nil,
        useCase: InitiateRoommateContactUseCase = InitiateRoommateContactUseCase(),
        now: @escaping () -> Date = Date.init
    ) {
        self.recipientID = recipientID
        self.currentUserID = currentUserID
        self.useCase = useCase
        self.now = now
        self.messages = messages ?? Self.sampleMessages(
            currentUserID: currentUserID,
            recipientID: recipientID,
            matchPercentage: matchPercentage,
            reference: now()
        )
    }

    /// Real data for a listing shared in this conversation, formatted like Home's listing cards.
    func sharedListing(withID listingID: String) -> ListingCardData? {
        HomeViewModel.sampleScoredListing(withID: listingID).map(ListingCardData.init(scored:))
    }

    var canSend: Bool {
        !trimmedDraft.isEmpty && !isSendTemporarilyDisabled
    }

    func send() {
        let content = trimmedDraft
        guard !content.isEmpty, !isSendTemporarilyDisabled else { return }
        do {
            let message = try useCase.execute(
                senderID: currentUserID,
                recipientID: recipientID,
                content: content,
                existingMessages: messages,
                // No share-listing flow yet, so plain messages never reference a listing.
                viewedOrSavedListingIDs: [],
                sentAt: now()
            )
            messages.append(message)
            draft = ""
            sendError = nil
        } catch let error as InitiateRoommateContactError {
            sendError = error
            switch error {
            case .rateLimitExceeded:
                startCooldown()
            case .unviewedSharedListing:
                break
            }
        } catch {
            // Defensive fallback, not expected to trigger: execute() only throws InitiateRoommateContactError,
            // but its untyped `throws` means Swift still requires an exhaustive catch here.
        }
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func startCooldown() {
        isSendTemporarilyDisabled = true
        cooldownTask?.cancel()
        cooldownTask = Task { [weak self] in
            try? await Task.sleep(for: Self.rateLimitCooldown)
            guard !Task.isCancelled, let self else { return }
            self.isSendTemporarilyDisabled = false
            self.sendError = nil
        }
    }
}

// Temporary sample data — stand-in until a Repository is introduced.
extension ConversationViewModel {
    /// Matches the current user's ID used in the other sample data (e.g. LifestyleProfile "current").
    static let sampleCurrentUserID = "current"

    /// Seeds Priya's thread with the mockup conversation, followed by 4 messages from the current user
    /// sent 1–4 seconds before `reference`. The rate limit allows 5 messages per minute, so the next send
    /// succeeds and the one after it is blocked — as long as both happen within ~55 seconds of opening.
    /// Other conversations start empty.
    static func sampleMessages(currentUserID: String, recipientID: String, matchPercentage: Int, reference: Date) -> [Message] {
        guard recipientID == "priya" else { return [] }

        func message(_ id: String, from sender: String, _ content: String, secondsBefore: TimeInterval, sharedListingID: String? = nil) -> Message {
            Message(
                messageID: id,
                senderID: sender,
                recipientID: sender == currentUserID ? recipientID : currentUserID,
                content: content,
                sentAt: reference.addingTimeInterval(-secondsBefore),
                sharedListingID: sharedListingID
            )
        }

        return [
            message("m1", from: recipientID, "Hi Emily! We matched at \(matchPercentage)% — I saw you're also looking around Ultimo for September. Are you still searching?", secondsBefore: 15 * 60),
            message("m2", from: currentUserID, "Hi Priya! Yes — my budget tops out at $420/week including bills. I've been looking at a terrace in Redfern, 12 min to UTS.", secondsBefore: 11 * 60),
            message("m3", from: currentUserID, "This is the one — what do you think?", secondsBefore: 10 * 60, sharedListingID: "L3"),
            message("m4", from: recipientID, "Looks great, and the light rail works for my campus days. I've booked a viewing for Wed 9 Sept at 12:30 — want to come along together?", secondsBefore: 6 * 60),
            // Rate-limit seed: 4 messages within the last minute.
            message("m5", from: currentUserID, "Yes, let's go together!", secondsBefore: 4),
            message("m6", from: currentUserID, "12:30 works for me.", secondsBefore: 3),
            message("m7", from: currentUserID, "Want to meet out the front?", secondsBefore: 2),
            message("m8", from: currentUserID, "I'll bring my rental references too.", secondsBefore: 1)
        ]
    }
}
