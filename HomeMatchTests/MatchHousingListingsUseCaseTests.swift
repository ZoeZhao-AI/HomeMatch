import XCTest
@testable import HomeMatch

final class MatchHousingListingsUseCaseTests: XCTestCase {

    private let sut = MatchHousingListingsUseCase()

    // MARK: - Fixtures

    private func makeContact() -> ListingContact {
        ListingContact(
            contactName: "Alex",
            contactType: .landlord,
            phoneNumber: "0400000000",
            email: nil
        )
    }

    private func makeListing(
        id: String = "L1",
        rent: Double = 400,
        location: String = "Ultimo, Sydney",
        roomType: RoomType = .privateRoom,
        isFurnished: Bool = true,
        isPetFriendly: Bool = false,
        facilities: [String] = ["wifi", "laundry"],
        minStay: Int = 6,
        photoURLs: [String] = []
    ) -> HousingListing {
        HousingListing(
            listingID: id,
            weeklyRent: rent,
            location: location,
            roomType: roomType,
            isFurnished: isFurnished,
            isPetFriendly: isPetFriendly,
            facilities: facilities,
            minStayDuration: minStay,
            photoURLs: photoURLs,
            contact: makeContact()
        )
    }

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

    // MARK: - 1. Happy path

    func testHappyPath_returnsResultsSortedByScoreDescending() throws {
        let strongMatch = makeListing(
            id: "L1", rent: 400, location: "Ultimo, Sydney",
            roomType: .privateRoom, facilities: ["wifi", "laundry", "aircon"]
        )
        let weakMatch = makeListing(
            id: "L2", rent: 800, location: "Bondi",
            roomType: .sharedRoom, facilities: []
        )
        let preference = makePreference(
            min: 300, max: 500,
            locations: ["Ultimo"],
            roomType: .privateRoom
        )

        let result = try sut.execute(
            listings: [weakMatch, strongMatch],
            preference: preference
        )

        XCTAssertEqual(result.all.count, 2)
        XCTAssertEqual(result.all[0].listing.listingID, "L1")
        XCTAssertEqual(result.all[1].listing.listingID, "L2")
        XCTAssertGreaterThan(result.all[0].score.overallScore, result.all[1].score.overallScore)
        XCTAssertEqual(result.recommended.count, 1)
        XCTAssertEqual(result.recommended[0].listing.listingID, "L1")
    }

    // MARK: - 2. noListingsAvailable

    func testEmptyListings_throwsNoListingsAvailable() {
        let preference = makePreference()
        XCTAssertThrowsError(try sut.execute(listings: [], preference: preference)) { error in
            guard case MatchHousingListingsError.noListingsAvailable = error else {
                XCTFail("Expected .noListingsAvailable, got \(error)")
                return
            }
        }
    }

    // MARK: - 3. Narrow preference — appears in `all` but not in `recommended`

    func testNarrowPreferenceProducingLowScore_appearsInAllButNotRecommended() throws {
        // Rent way beyond budget max (>20% tolerance): budgetScore → 0.
        // Location "Melbourne" not present in preferred ["Ultimo"]: locationScore → 0.
        // Room type mismatch: roomTypeScore → 0.
        // Pet-friendly required but listing not pet-friendly: facilitiesScore → 0.
        let listing = makeListing(
            id: "L1", rent: 2000, location: "Melbourne",
            roomType: .sharedRoom, isPetFriendly: false, facilities: []
        )
        let preference = makePreference(
            min: 300, max: 500,
            locations: ["Ultimo"],
            roomType: .privateRoom,
            requiresPetFriendly: true
        )

        let result = try sut.execute(listings: [listing], preference: preference)

        XCTAssertEqual(result.all.count, 1)
        XCTAssertEqual(result.all[0].listing.listingID, "L1")
        XCTAssertFalse(result.all[0].score.isRecommended)
        XCTAssertTrue(result.recommended.isEmpty)
    }

    // MARK: - 4. 7-day exclusion

    func testSevenDayExclusion_recentListingFiltered_oldListingIncluded() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let threeDaysAgo = now.addingTimeInterval(-3 * 24 * 60 * 60)
        let tenDaysAgo = now.addingTimeInterval(-10 * 24 * 60 * 60)

        let recentListing = makeListing(id: "L_recent")
        let oldListing = makeListing(id: "L_old")

        let recentlyShown: [String: Date] = [
            "L_recent": threeDaysAgo,
            "L_old": tenDaysAgo
        ]

        let result = try sut.execute(
            listings: [recentListing, oldListing],
            preference: makePreference(),
            recentlyShown: recentlyShown,
            now: now
        )

        XCTAssertEqual(result.all.count, 1)
        XCTAssertEqual(result.all[0].listing.listingID, "L_old")
    }

    // MARK: - 5. Hard requirements — a high score alone is not enough to be recommended

    func testOverBudget_highScoreButNotRecommended_stillInAll() throws {
        // Rent 550 vs max 500 → budget score 50, overall 78 (above 60), but over the max.
        let listing = makeListing(id: "L1", rent: 550)
        let result = try sut.execute(listings: [listing], preference: makePreference())

        XCTAssertGreaterThanOrEqual(result.all[0].score.overallScore, 60)
        XCTAssertTrue(result.recommended.isEmpty)
        XCTAssertEqual(result.all.count, 1, "Over-budget listing must remain available under Show all")
    }

    func testBelowBudgetMinimum_isStillRecommended() throws {
        // Cheaper than the minimum is not a hard requirement — it only lowers the budget score.
        let listing = makeListing(id: "L1", rent: 280)
        let result = try sut.execute(listings: [listing], preference: makePreference(min: 300, max: 500))

        XCTAssertEqual(result.recommended.map { $0.listing.listingID }, ["L1"])
    }

    func testWrongRoomType_highScoreButNotRecommended() throws {
        let listing = makeListing(id: "L1", roomType: .sharedRoom)
        let result = try sut.execute(listings: [listing], preference: makePreference(roomType: .privateRoom))

        XCTAssertGreaterThanOrEqual(result.all[0].score.overallScore, 60)
        XCTAssertTrue(result.recommended.isEmpty)
    }

    func testPetFriendlyRequired_nonPetFriendlyListingNotRecommended() throws {
        let listing = makeListing(id: "L1", isPetFriendly: false)
        let result = try sut.execute(listings: [listing], preference: makePreference(requiresPetFriendly: true))

        XCTAssertGreaterThanOrEqual(result.all[0].score.overallScore, 60)
        XCTAssertTrue(result.recommended.isEmpty)
    }

    // MARK: - 6. Suburb matching — whole suburb, not substring

    func testSuburbMatch_sydneyDoesNotMatchNorthSydneyOrOlympicPark() throws {
        let north = makeListing(id: "L_north", location: "North Sydney")
        let olympic = makeListing(id: "L_olympic", location: "1 Olympic Blvd, Sydney Olympic Park NSW 2127")
        let city = makeListing(id: "L_city", location: "5 George St, Sydney NSW 2000")
        let result = try sut.execute(listings: [north, olympic, city],
                                     preference: makePreference(locations: ["Sydney"]))

        XCTAssertEqual(result.recommended.map { $0.listing.listingID }, ["L_city"])
        let north0 = result.all.first { $0.listing.listingID == "L_north" }!
        XCTAssertEqual(north0.score.locationMatchScore, 0)
    }

    func testSuburbMatch_fullAddressWithStateAndPostcode_matchesIgnoringCase() {
        XCTAssertTrue(MatchHousingListingsUseCase.isInPreferredSuburb(
            "42 Broadway St, Ultimo NSW 2007", preferred: ["ultimo"]))
        XCTAssertTrue(MatchHousingListingsUseCase.isInPreferredSuburb(
            "Ultimo, Sydney", preferred: ["  Ultimo "]))
        XCTAssertFalse(MatchHousingListingsUseCase.isInPreferredSuburb(
            "42 Broadway St, Ultimo NSW 2007", preferred: ["Ulti"]))
    }
}
