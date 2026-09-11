import XCTest
@testable import HomeMatch

final class InitiateRoommateContactUseCaseTests: XCTestCase {

    private let sut = InitiateRoommateContactUseCase()
    private let sender = "S"
    private let recipient = "R"
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Fixtures

    private func makeMessage(
        sender: String,
        recipient: String,
        secondsBefore: TimeInterval,
        sharedListingID: String? = nil
    ) -> Message {
        Message(
            messageID: UUID().uuidString,
            senderID: sender,
            recipientID: recipient,
            content: "hi",
            sentAt: now.addingTimeInterval(-secondsBefore),
            sharedListingID: sharedListingID
        )
    }

    // MARK: - 1. Happy path

    func testHappyPath_noExistingMessages_returnsMessage() throws {
        let msg = try sut.execute(
            senderID: sender,
            recipientID: recipient,
            content: "hello",
            existingMessages: [],
            viewedOrSavedListingIDs: [],
            sentAt: now
        )
        XCTAssertEqual(msg.senderID, sender)
        XCTAssertEqual(msg.recipientID, recipient)
        XCTAssertEqual(msg.content, "hello")
        XCTAssertNil(msg.sharedListingID)
        XCTAssertEqual(msg.sentAt, now)
    }

    // MARK: - 2. Rate limit boundary — 5 prior → 6th throws

    func testFivePriorMessagesWithinLastMinute_sixthThrowsRateLimit() {
        let existing = (1...5).map { i in
            makeMessage(sender: sender, recipient: recipient, secondsBefore: Double(i * 10))
        }
        XCTAssertThrowsError(try sut.execute(
            senderID: sender,
            recipientID: recipient,
            content: "hi",
            existingMessages: existing,
            viewedOrSavedListingIDs: [],
            sentAt: now
        )) { error in
            guard case InitiateRoommateContactError.rateLimitExceeded = error else {
                XCTFail("Expected .rateLimitExceeded, got \(error)")
                return
            }
        }
    }

    // MARK: - 3. Rate limit not triggered — 4 prior → 5th succeeds

    func testFourPriorMessagesWithinLastMinute_fifthSucceeds() throws {
        let existing = (1...4).map { i in
            makeMessage(sender: sender, recipient: recipient, secondsBefore: Double(i * 10))
        }
        _ = try sut.execute(
            senderID: sender,
            recipientID: recipient,
            content: "hi",
            existingMessages: existing,
            viewedOrSavedListingIDs: [],
            sentAt: now
        )
    }

    // MARK: - 4. Sharing an unviewed listing

    func testSharingUnviewedListing_throwsUnviewedSharedListing() {
        XCTAssertThrowsError(try sut.execute(
            senderID: sender,
            recipientID: recipient,
            content: "check this",
            sharedListingID: "L1",
            existingMessages: [],
            viewedOrSavedListingIDs: [],
            sentAt: now
        )) { error in
            guard case InitiateRoommateContactError.unviewedSharedListing = error else {
                XCTFail("Expected .unviewedSharedListing, got \(error)")
                return
            }
        }
    }

    // MARK: - 5. Sharing a viewed listing

    func testSharingViewedListing_succeeds() throws {
        let msg = try sut.execute(
            senderID: sender,
            recipientID: recipient,
            content: "check this",
            sharedListingID: "L1",
            existingMessages: [],
            viewedOrSavedListingIDs: ["L1"],
            sentAt: now
        )
        XCTAssertEqual(msg.sharedListingID, "L1")
    }

    // MARK: - 6. Messages outside the 1-minute window don't count

    func testMessagesOutsideOneMinuteWindow_notCountedTowardRateLimit() throws {
        // 5 messages sent ~2 minutes ago — should NOT count toward the rate limit.
        let existing = (1...5).map { i in
            makeMessage(sender: sender, recipient: recipient, secondsBefore: 120 + Double(i))
        }
        _ = try sut.execute(
            senderID: sender,
            recipientID: recipient,
            content: "hi",
            existingMessages: existing,
            viewedOrSavedListingIDs: [],
            sentAt: now
        )
    }
}
