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
/// Business Rule: a listing is only recommended if it meets every hard requirement — rent at or
/// below the budget maximum, located in one of the preferred suburbs, the exact preferred room
/// type, and pet-friendly when the user requires it. A listing that breaks a hard requirement is
/// never recommended, however high it scores, but it stays in the full list for "Show all".
/// Rent below the budget minimum is not a hard requirement; it only lowers the budget score.
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

        // Normalised once per call rather than once per listing.
        let preferredSuburbs = Set(preference.preferredLocations.map(Self.normalisedSuburb))

        let all = eligible
            .map { listing in
                (listing: listing, score: score(for: listing, against: preference, preferredSuburbs: preferredSuburbs))
            }
            .sorted { $0.score.overallScore > $1.score.overallScore }

        let recommended = all.filter {
            $0.score.isRecommended && meetsHardRequirements($0.listing, score: $0.score, preference: preference)
        }

        return MatchHousingListingsResult(recommended: recommended, all: all)
    }

    private func meetsHardRequirements(_ listing: HousingListing, score: ListingMatchScore,
                                       preference: HousingPreference) -> Bool {
        listing.weeklyRent <= preference.budgetRange.max
            && score.locationMatchScore == 100   // in a preferred suburb (see `isInPreferredSuburb`)
            && listing.roomType == preference.preferredRoomType
            && (!preference.requiresPetFriendly || listing.isPetFriendly)
    }

    /// Whether a listing's location is in one of the preferred suburbs. The location is split into
    /// its comma-separated parts (e.g. "42 Broadway St, Ultimo NSW 2007" → "42 Broadway St",
    /// "Ultimo NSW 2007"), any trailing state and postcode is removed, and a part must equal a
    /// preferred suburb exactly (ignoring case and surrounding spaces). Whole-suburb matching stops
    /// "Sydney" from matching "North Sydney" or "Sydney Olympic Park".
    static func isInPreferredSuburb(_ location: String, preferred: [String]) -> Bool {
        isInSuburbs(location, Set(preferred.map(normalisedSuburb)))
    }

    private static func isInSuburbs(_ location: String, _ normalisedPreferred: Set<String>) -> Bool {
        location.split(separator: ",").contains { normalisedPreferred.contains(normalisedSuburb($0)) }
    }

    private static let stateCodes: Set<String> = ["nsw", "vic", "qld", "sa", "wa", "tas", "act", "nt"]

    /// Lower-cases, collapses whitespace, and drops a trailing "STATE" or "STATE 1234"
    /// (e.g. "Ultimo NSW 2007" → "ultimo"). A state code on its own is kept.
    private static func normalisedSuburb<S: StringProtocol>(_ text: S) -> String {
        var words = text.lowercased().split(whereSeparator: \.isWhitespace)
        if words.count >= 3, words[words.count - 1].count == 4,
           words[words.count - 1].allSatisfy(\.isASCII), words[words.count - 1].allSatisfy(\.isNumber),
           stateCodes.contains(String(words[words.count - 2])) {
            words.removeLast(2)
        } else if words.count >= 2, stateCodes.contains(String(words[words.count - 1])) {
            words.removeLast()
        }
        return words.joined(separator: " ")
    }

    private func score(for listing: HousingListing, against preference: HousingPreference,
                       preferredSuburbs: Set<String>) -> ListingMatchScore {
        ListingMatchScore(
            listingID: listing.listingID,
            budgetMatchScore: budgetScore(rent: listing.weeklyRent, range: preference.budgetRange),
            locationMatchScore: locationScore(listing: listing.location, preferredSuburbs: preferredSuburbs),
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

    private func locationScore(listing: String, preferredSuburbs: Set<String>) -> Double {
        Self.isInSuburbs(listing, preferredSuburbs) ? 100 : 0
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
