import Foundation

struct MatchHousingListingsUseCase {
    func execute(
        listings: [HousingListing],
        preference: HousingPreference
    ) -> [(listing: HousingListing, score: ListingMatchScore)] {
        listings
            .map { listing in
                (listing: listing, score: score(for: listing, against: preference))
            }
            .sorted { $0.score.overallScore > $1.score.overallScore }
    }

    private func score(for listing: HousingListing, against preference: HousingPreference) -> ListingMatchScore {
        ListingMatchScore(
            listingID: listing.listingID,
            budgetMatchScore: budgetScore(rent: listing.weeklyRent, range: preference.budgetRange),
            locationMatchScore: locationScore(listing: listing.location, preferred: preference.preferredLocation),
            roomTypeMatchScore: roomTypeScore(listing: listing.roomType, preferred: preference.preferredRoomType),
            facilitiesMatchScore: facilitiesScore(listing: listing, requiresPetFriendly: preference.requiresPetFriendly)
        )
    }

    private func budgetScore(rent: Double, range: BudgetRange) -> Double {
        (rent >= range.min && rent <= range.max) ? 100 : 0
    }

    private func locationScore(listing: String, preferred: String) -> Double {
        listing.caseInsensitiveCompare(preferred) == .orderedSame ? 100 : 0
    }

    private func roomTypeScore(listing: RoomType, preferred: RoomType) -> Double {
        switch (listing, preferred) {
        case (.privateRoom, .privateRoom),
             (.sharedRoom, .sharedRoom),
             (.entirePlace, .entirePlace):
            return 100
        default:
            return 0
        }
    }

    private func facilitiesScore(listing: HousingListing, requiresPetFriendly: Bool) -> Double {
        if requiresPetFriendly && !listing.isPetFriendly {
            return 0
        }
        return 100
    }
}
