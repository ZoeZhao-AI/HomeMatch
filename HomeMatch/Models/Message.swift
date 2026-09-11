import Foundation

/// Represents a single message sent within a conversation thread between two users.
/// Business Rule: a user cannot send more than 5 messages to the same recipient
/// within a 1-minute window (enforced in the Use Case layer).
/// Business Rule: sharedListingID, if set, must reference a listing the sender
/// has already viewed or saved (enforced in the Use Case layer).
struct Message {
    let messageID: String
    let senderID: String
    let recipientID: String
    let content: String
    let sentAt: Date
    let sharedListingID: String?    // optional — set if this message shares a listing

    var timestamp: Date { sentAt }
}
