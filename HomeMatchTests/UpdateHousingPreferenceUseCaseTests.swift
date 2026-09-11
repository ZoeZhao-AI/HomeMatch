import XCTest
@testable import HomeMatch

final class UpdateHousingPreferenceUseCaseTests: XCTestCase {

    private let sut = UpdateHousingPreferenceUseCase()

    // MARK: - Fixtures

    private func makePreference(
        min: Double = 300,
        max: Double = 500,
        locations: [String] = ["Ultimo"],
        roomType: RoomType = .privateRoom,
        requiresPetFriendly: Bool = false
    ) -> HousingPreference {
        HousingPreference(
            budgetRange: BudgetRange(min: min, max: max)!,
            preferredLocations: locations,
            preferredRoomType: roomType,
            requiresPetFriendly: requiresPetFriendly
        )
    }

    // MARK: - 1. Happy path — new values differ

    func testValuesDifferFromCurrent_returnsUpdated() throws {
        let current = makePreference(
            min: 300, max: 500,
            locations: ["Ultimo"],
            roomType: .privateRoom,
            requiresPetFriendly: false
        )

        let outcome = try sut.execute(
            current: current,
            budgetMin: 350,
            budgetMax: 600,
            preferredLocations: ["Ultimo", "Chippendale"],
            preferredRoomType: .privateRoom,
            requiresPetFriendly: true
        )

        guard case .updated(let pref) = outcome else {
            XCTFail("Expected .updated, got \(outcome)")
            return
        }
        XCTAssertEqual(pref.budgetRange, BudgetRange(min: 350, max: 600))
        XCTAssertEqual(pref.preferredLocations, ["Ultimo", "Chippendale"])
        XCTAssertEqual(pref.preferredRoomType, .privateRoom)
        XCTAssertTrue(pref.requiresPetFriendly)
    }

    // MARK: - 2. Invalid budget range (max < min)

    func testMaxLessThanMin_throwsInvalidBudgetRange() {
        let current = makePreference()

        XCTAssertThrowsError(try sut.execute(
            current: current,
            budgetMin: 500,
            budgetMax: 300,
            preferredLocations: ["Ultimo"],
            preferredRoomType: .privateRoom,
            requiresPetFriendly: false
        )) { error in
            guard case UpdateHousingPreferenceError.invalidBudgetRange = error else {
                XCTFail("Expected .invalidBudgetRange, got \(error)")
                return
            }
        }
    }

    // MARK: - 3. Unchanged — values identical to current

    func testValuesIdenticalToCurrent_returnsUnchanged() throws {
        let current = makePreference(
            min: 300, max: 500,
            locations: ["Ultimo"],
            roomType: .privateRoom,
            requiresPetFriendly: false
        )

        let outcome = try sut.execute(
            current: current,
            budgetMin: 300,
            budgetMax: 500,
            preferredLocations: ["Ultimo"],
            preferredRoomType: .privateRoom,
            requiresPetFriendly: false
        )

        guard case .unchanged(let pref) = outcome else {
            XCTFail("Expected .unchanged, got \(outcome)")
            return
        }
        XCTAssertEqual(pref, current)
    }

    // MARK: - 4. Boundary — max equals min

    func testBudgetMaxEqualsMin_throwsInvalidBudgetRange() {
        // BudgetRange requires `max > min` strictly, so max == min fails
        // validation and the use case throws .invalidBudgetRange.
        let current = makePreference()

        XCTAssertThrowsError(try sut.execute(
            current: current,
            budgetMin: 400,
            budgetMax: 400,
            preferredLocations: ["Ultimo"],
            preferredRoomType: .privateRoom,
            requiresPetFriendly: false
        )) { error in
            guard case UpdateHousingPreferenceError.invalidBudgetRange = error else {
                XCTFail("Expected .invalidBudgetRange, got \(error)")
                return
            }
        }
    }
}
