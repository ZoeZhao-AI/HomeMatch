import XCTest
@testable import HomeMatch

final class ScheduleViewingUseCaseTests: XCTestCase {

    private let sut = ScheduleViewingUseCase()
    private let userID = "U1"
    private let listingID = "L1"

    // MARK: - Fixtures

    private func futureTime(secondsFromNow: TimeInterval = 3 * 24 * 60 * 60) -> Date {
        Date().addingTimeInterval(secondsFromNow)
    }

    private func pastTime(secondsBefore: TimeInterval = 60) -> Date {
        Date().addingTimeInterval(-secondsBefore)
    }

    private func makeExistingRequest(
        listingID: String,
        userID: String = "U1",
        status: ViewingRequestStatus = .pending,
        createdAgoSeconds: TimeInterval = 60 * 60
    ) -> ViewingRequest {
        ViewingRequest(
            requestID: UUID().uuidString,
            listingID: listingID,
            userID: userID,
            // ViewingRequest.init requires requestedTime > Date(), so use 7 days out.
            requestedTime: Date().addingTimeInterval(7 * 24 * 60 * 60),
            status: status,
            createdAt: Date().addingTimeInterval(-createdAgoSeconds)
        )!
    }

    // MARK: - 1. Happy path

    func testHappyPath_returnsPendingViewingRequest() throws {
        let requested = futureTime()

        let result = try sut.execute(
            listingID: listingID,
            userID: userID,
            requestedTime: requested,
            existingRequests: []
        )

        XCTAssertEqual(result.listingID, listingID)
        XCTAssertEqual(result.userID, userID)
        XCTAssertEqual(result.requestedTime, requested)
        XCTAssertEqual(result.status, .pending)
    }

    // MARK: - 2. Past time

    func testPastTime_throwsPastRequestedTime() {
        XCTAssertThrowsError(try sut.execute(
            listingID: listingID,
            userID: userID,
            requestedTime: pastTime(),
            existingRequests: []
        )) { error in
            guard case ScheduleViewingError.pastRequestedTime = error else {
                XCTFail("Expected .pastRequestedTime, got \(error)")
                return
            }
        }
    }

    // MARK: - 3. Duplicate within 24 hours

    func testDuplicateWithin24Hours_throws() {
        let existing = makeExistingRequest(
            listingID: listingID,
            createdAgoSeconds: 14 * 60 * 60  // 14 hours ago — within the 24-hour window
        )

        XCTAssertThrowsError(try sut.execute(
            listingID: listingID,
            userID: userID,
            requestedTime: futureTime(),
            existingRequests: [existing]
        )) { error in
            guard case ScheduleViewingError.duplicateRequestWithin24Hours = error else {
                XCTFail("Expected .duplicateRequestWithin24Hours, got \(error)")
                return
            }
        }
    }

    // MARK: - 4. Too many pending

    func testThreePendingRequests_throwsTooManyPending() {
        let pending1 = makeExistingRequest(listingID: "L_a", status: .pending)
        let pending2 = makeExistingRequest(listingID: "L_b", status: .pending)
        let pending3 = makeExistingRequest(listingID: "L_c", status: .pending)

        XCTAssertThrowsError(try sut.execute(
            listingID: listingID,
            userID: userID,
            requestedTime: futureTime(),
            existingRequests: [pending1, pending2, pending3]
        )) { error in
            guard case ScheduleViewingError.tooManyPendingRequests = error else {
                XCTFail("Expected .tooManyPendingRequests, got \(error)")
                return
            }
        }
    }

    // MARK: - 5. Edge case — 3 pending AND past time

    func testThreePendingPlusPastTime_throwsTooManyPending_becausePendingIsCheckedFirst() {
        // Check order in the use case: (1) pending-count, (2) 24-hour duplicate,
        // (3) delegate to ViewingRequest.init for past-time. When both conditions
        // are violated (3 pending + past requestedTime), the pending-count check
        // fires first, so .tooManyPendingRequests wins over .pastRequestedTime.
        let pending1 = makeExistingRequest(listingID: "L_a", status: .pending)
        let pending2 = makeExistingRequest(listingID: "L_b", status: .pending)
        let pending3 = makeExistingRequest(listingID: "L_c", status: .pending)

        XCTAssertThrowsError(try sut.execute(
            listingID: listingID,
            userID: userID,
            requestedTime: pastTime(),
            existingRequests: [pending1, pending2, pending3]
        )) { error in
            guard case ScheduleViewingError.tooManyPendingRequests = error else {
                XCTFail("Expected .tooManyPendingRequests, got \(error)")
                return
            }
        }
    }
}
