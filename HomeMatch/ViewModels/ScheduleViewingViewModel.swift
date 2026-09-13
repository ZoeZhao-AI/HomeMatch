import Foundation
import Combine

@MainActor
final class ScheduleViewingViewModel: ObservableObject {
    enum SubmissionState {
        case idle
        case requested(ViewingRequest)
        case failed(ScheduleViewingError)
    }

    @Published private(set) var submissionState: SubmissionState = .idle
    @Published private(set) var pendingCount: Int

    let listingID: String
    private let userID: String
    private let store: SampleViewingRequestStore
    private let useCase: ScheduleViewingUseCase

    init(
        listingID: String,
        userID: String = SampleViewingRequestStore.currentUserID,
        store: SampleViewingRequestStore = .shared,
        useCase: ScheduleViewingUseCase = ScheduleViewingUseCase()
    ) {
        self.listingID = listingID
        self.userID = userID
        self.store = store
        self.useCase = useCase
        self.pendingCount = store.pendingCount(for: userID)
    }

    func requestViewing(at requestedTime: Date) {
        do {
            let request = try useCase.execute(
                listingID: listingID,
                userID: userID,
                requestedTime: requestedTime,
                existingRequests: store.requests
            )
            store.add(request)
            pendingCount = store.pendingCount(for: userID)
            submissionState = .requested(request)
        } catch let error as ScheduleViewingError {
            submissionState = .failed(error)
        } catch {
            // Defensive fallback, not expected to trigger: execute() only throws ScheduleViewingError,
            // but its untyped `throws` means Swift still requires an exhaustive catch here.
            submissionState = .idle
        }
    }

    func clearSubmissionState() {
        submissionState = .idle
    }
}

/// Temporary in-memory stand-in until a Repository is introduced. Shared across screens so
/// requests made on one listing count towards the pending limit on the others.
@MainActor
final class SampleViewingRequestStore {
    static let shared = SampleViewingRequestStore()

    /// Matches the current user's ID used in the other sample data (e.g. LifestyleProfile "current").
    static let currentUserID = "current"

    private(set) var requests: [ViewingRequest]

    /// Pass `nil` to seed with the sample pending request.
    init(requests: [ViewingRequest]? = nil) {
        self.requests = requests ?? Self.sampleRequests()
    }

    func add(_ request: ViewingRequest) {
        requests.append(request)
    }

    func pendingCount(for userID: String) -> Int {
        requests.filter { $0.userID == userID && $0.status == .pending }.count
    }

    /// One pending request for a listing outside Home's sample data, made two days ago,
    /// so it counts towards the 3-pending limit without triggering the 24-hour duplicate rule.
    private static func sampleRequests() -> [ViewingRequest] {
        let now = Date()
        let request = ViewingRequest(
            requestID: "sample-pending-1",
            listingID: "L-previous",
            userID: currentUserID,
            requestedTime: now.addingTimeInterval(3 * 24 * 60 * 60),
            status: .pending,
            createdAt: now.addingTimeInterval(-2 * 24 * 60 * 60)
        )
        return [request].compactMap { $0 }
    }
}
