import Foundation

enum InitiateRoommateContactError: Error, LocalizedError {
    case rateLimitExceeded
    case unviewedSharedListing

    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "You're sending messages too quickly. Please wait a moment."
        case .unviewedSharedListing:
            return "Please view this listing first before sharing it."
        }
    }
}

struct InitiateRoommateContactUseCase {
    private static let rateLimitWindow: TimeInterval = 60
    private static let rateLimitMax = 5

    func execute(
        senderID: String,
        recipientID: String,
        content: String,
        sharedListingID: String? = nil,
        existingMessages: [Message],
        viewedOrSavedListingIDs: Set<String>,
        messageID: String = UUID().uuidString,
        sentAt: Date = Date()
    ) throws -> Message {
        let cutoff = sentAt.addingTimeInterval(-Self.rateLimitWindow)
        let recentCount = existingMessages.filter {
            $0.senderID == senderID &&
            $0.recipientID == recipientID &&
            $0.sentAt >= cutoff &&
            $0.sentAt <= sentAt
        }.count
        if recentCount >= Self.rateLimitMax {
            throw InitiateRoommateContactError.rateLimitExceeded
        }

        if let sharedListingID, !viewedOrSavedListingIDs.contains(sharedListingID) {
            throw InitiateRoommateContactError.unviewedSharedListing
        }

        return Message(
            messageID: messageID,
            senderID: senderID,
            recipientID: recipientID,
            content: content,
            sentAt: sentAt,
            sharedListingID: sharedListingID
        )
    }
}
