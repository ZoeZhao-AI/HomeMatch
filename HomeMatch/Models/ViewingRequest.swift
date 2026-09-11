import Foundation

struct ViewingRequest {
    let requestID: String
    let listingID: String
    let userID: String
    let requestedTime: Date
    var status: ViewingRequestStatus
    let createdAt: Date

    init?(requestID: String, listingID: String, userID: String,
          requestedTime: Date, status: ViewingRequestStatus, createdAt: Date) {
        guard requestedTime > Date() else { return nil }
        self.requestID = requestID
        self.listingID = listingID
        self.userID = userID
        self.requestedTime = requestedTime
        self.status = status
        self.createdAt = createdAt
    }

    var timestamp: Date { createdAt }
}

enum ViewingRequestStatus {
    case pending
    case confirmed
    case declined
    case cancelled
}
