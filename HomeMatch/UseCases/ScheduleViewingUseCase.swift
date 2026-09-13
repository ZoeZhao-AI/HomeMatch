import Foundation

enum ScheduleViewingError: Error, LocalizedError {
    case pastRequestedTime
    case duplicateRequestWithin24Hours
    case tooManyPendingRequests

    var errorDescription: String? {
        switch self {
        case .pastRequestedTime:
            return "Please choose a future time slot to schedule your viewing."
        case .duplicateRequestWithin24Hours:
            return "You've already requested a viewing for this listing. Please wait for confirmation or try again after 24 hours."
        case .tooManyPendingRequests:
            return "You already have 3 pending viewings. Please complete or cancel one before scheduling another."
        }
    }
}

/// Represents the business operation of a user requesting an in-person viewing of a listing,
/// producing a new `ViewingRequest` with a pending status. The request is returned, not stored —
/// saving it is the caller's responsibility.
/// Business Rule: a user cannot hold more than 3 pending viewing requests at once.
/// Business Rule: a user cannot request a viewing of the same listing more than once within
/// 24 hours, regardless of what happened to the earlier request.
/// Business Rule: the requested viewing time must be in the future (enforced by `ViewingRequest`).
/// When more than one rule is broken, they are checked in the order above, so the pending limit
/// is reported first.
struct ScheduleViewingUseCase {
    private static let maxPendingRequests = 3
    private static let duplicateWindow: TimeInterval = 24 * 60 * 60

    func execute(
        listingID: String,
        userID: String,
        requestedTime: Date,
        existingRequests: [ViewingRequest],
        requestID: String = UUID().uuidString,
        createdAt: Date = Date()
    ) throws -> ViewingRequest {
        let userRequests = existingRequests.filter { $0.userID == userID }

        let pendingCount = userRequests.filter { $0.status == .pending }.count
        if pendingCount >= Self.maxPendingRequests {
            throw ScheduleViewingError.tooManyPendingRequests
        }

        let cutoff = createdAt.addingTimeInterval(-Self.duplicateWindow)
        let hasRecent = userRequests.contains {
            $0.listingID == listingID && $0.createdAt >= cutoff
        }
        if hasRecent {
            throw ScheduleViewingError.duplicateRequestWithin24Hours
        }

        guard let request = ViewingRequest(
            requestID: requestID,
            listingID: listingID,
            userID: userID,
            requestedTime: requestedTime,
            status: .pending,
            createdAt: createdAt
        ) else {
            throw ScheduleViewingError.pastRequestedTime
        }
        return request
    }
}
