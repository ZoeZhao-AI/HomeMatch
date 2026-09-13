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

/// Represents the business operation of the current user sending a message to a candidate
/// roommate, optionally sharing a housing listing within the conversation. The message is
/// returned, not stored — saving it is the caller's responsibility.
/// Business Rule: a user cannot send more than 5 messages to the same recipient within a
/// 1-minute window (anti-spam), so a 6th message inside that minute is rejected.
/// Business Rule: a shared listing must be one the sender has already viewed or saved.
/// When both rules are broken, the rate limit is reported first.
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
