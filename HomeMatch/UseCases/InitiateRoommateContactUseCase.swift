import Foundation

struct InitiateRoommateContactUseCase {
    func execute(
        senderID: String,
        recipientID: String,
        content: String,
        sharedListingID: String? = nil,
        messageID: String = UUID().uuidString,
        sentAt: Date = Date()
    ) -> Message {
        Message(
            messageID: messageID,
            senderID: senderID,
            recipientID: recipientID,
            content: content,
            sentAt: sentAt,
            sharedListingID: sharedListingID
        )
    }
}
