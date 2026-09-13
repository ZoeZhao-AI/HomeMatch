import Foundation

enum MatchHousingListingsError: Error, LocalizedError {
    case noListingsAvailable

    var errorDescription: String? {
        switch self {
        case .noListingsAvailable:
            return "No listings are available right now. Please check back soon."
        }
    }
}

struct MatchHousingListingsResult {
    let recommended: [(listing: HousingListing, score: ListingMatchScore)]
    let all: [(listing: HousingListing, score: ListingMatchScore)]
}

/// Represents the business operation of ranking housing listings against a user's saved
/// `HousingPreference`, producing the recommendations shown on the home screen.
/// Each listing is scored on budget, location, room type and facilities (see `ListingMatchScore`),
/// and results are ordered from best to worst match.
/// Business Rule: listings scoring below 60% are not actively recommended, but they are still
/// returned in the full list so the user can choose "Show all".
/// Business Rule: a listing shown to the user within the last 7 days is left out, to avoid
/// repeatedly showing the same result.
/// Business Rule: an error is only thrown when there are no listings at all — low scores on their
/// own are not an error, since the user must still be able to reveal those results.
struct MatchHousingListingsUseCase {
    private static let recencyWindow: TimeInterval = 7 * 24 * 60 * 60

    func execute(
        listings: [HousingListing],
        preference: HousingPreference,
        recentlyShown: [String: Date] = [:],
        now: Date = Date()
    ) throws -> MatchHousingListingsResult {
        guard !listings.isEmpty else {
            throw MatchHousingListingsError.noListingsAvailable
        }

        let cutoff = now.addingTimeInterval(-Self.recencyWindow)
        let eligible = listings.filter { listing in
            guard let lastShown = recentlyShown[listing.listingID] else { return true }
            return lastShown < cutoff
        }

        let all = eligible
            .map { listing in
                (listing: listing, score: score(for: listing, against: preference))
            }
            .sorted { $0.score.overallScore > $1.score.overallScore }

        let recommended = all.filter { $0.score.isRecommended }

        return MatchHousingListingsResult(recommended: recommended, all: all)
    }

    private func score(for listing: HousingListing, against preference: HousingPreference) -> ListingMatchScore {
        ListingMatchScore(
            listingID: listing.listingID,
            budgetMatchScore: budgetScore(rent: listing.weeklyRent, range: preference.budgetRange),
            locationMatchScore: locationScore(listing: listing.location, preferred: preference.preferredLocations),
            roomTypeMatchScore: roomTypeScore(listing: listing.roomType, preferred: preference.preferredRoomType),
            facilitiesMatchScore: facilitiesScore(listing: listing, requiresPetFriendly: preference.requiresPetFriendly)
        )
    }

    private func budgetScore(rent: Double, range: BudgetRange) -> Double {
        if rent >= range.min && rent <= range.max {
            return 100
        }
        if rent > range.max {
            let overage = rent - range.max
            let tolerance = range.max * 0.20
            return max(0, 100 * (1 - overage / tolerance))
        }
        let shortfall = range.min - rent
        let tolerance = range.min * 0.20
        return max(0, 100 * (1 - shortfall / tolerance))
    }

    private func locationScore(listing: String, preferred: [String]) -> Double {
        preferred.contains { location in
            listing.range(of: location, options: .caseInsensitive) != nil
        } ? 100 : 0
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
        // HousingPreference has no facilities list to match against, so the array
        // is used as a richness signal: baseline 50 for satisfying pet-friendly,
        // plus up to 50 scaled linearly by facility count (capped at 5).
        let capped = min(listing.facilities.count, 5)
        return 50 + (Double(capped) / 5.0) * 50
    }
}
