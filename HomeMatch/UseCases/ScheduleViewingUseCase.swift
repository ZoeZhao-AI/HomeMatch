import Foundation

enum ScheduleViewingError: Error, LocalizedError {
    case pastRequestedTime

    var errorDescription: String? {
        switch self {
        case .pastRequestedTime:
            return "Please choose a future time slot to schedule your viewing."
        }
    }
}

struct ScheduleViewingUseCase {
    func execute(
        listingID: String,
        userID: String,
        requestedTime: Date,
        requestID: String = UUID().uuidString,
        createdAt: Date = Date()
    ) throws -> ViewingRequest {
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
