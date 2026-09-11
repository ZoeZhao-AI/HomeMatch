import Foundation

/// Represents a request by a user to schedule an in-person viewing of a listing.
/// Business Rule: requestedTime must be in the future at the time of creation.
/// Business Rule: a user cannot hold more than 3 pending requests at once
/// (enforced in the Use Case layer, since it requires querying across multiple ViewingRequest instances).
/// Business Rule: a user cannot submit more than one request for the same listing
/// within 24 hours (enforced in the Use Case layer, for the same reason).
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
