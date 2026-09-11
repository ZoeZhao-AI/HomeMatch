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
