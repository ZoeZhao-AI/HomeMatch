import Foundation

struct Message {
    let messageID: String
    let senderID: String
    let recipientID: String
    let content: String
    let sentAt: Date
    let sharedListingID: String?    // optional — set if this message shares a listing

    var timestamp: Date { sentAt }
}
