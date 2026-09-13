import Foundation

enum UpdateHousingPreferenceError: Error, LocalizedError {
    case invalidBudgetRange
    case missingRoomTypeSelection

    var errorDescription: String? {
        switch self {
        case .invalidBudgetRange:
            return "Your maximum budget must be higher than your minimum. Please check and re-enter."
        case .missingRoomTypeSelection:
            return "Please select a room type before saving."
        }
    }
}

enum UpdateHousingPreferenceOutcome {
    case unchanged(HousingPreference)
    case updated(HousingPreference)
}

/// Represents the business operation of a user saving changes to their existing
/// `HousingPreference`, which tells the app whether listings need to be matched again.
/// Business Rule: the budget's maximum must be higher than its minimum, and both must be positive
/// (enforced by `BudgetRange`).
/// Business Rule: if the new preference is identical to the current one, the result is reported as
/// unchanged, so matching is not re-run unnecessarily.
/// A room type is always required: this operation only accepts a chosen `RoomType`, so a missing
/// selection must be caught before calling it (reported as `missingRoomTypeSelection`).
struct UpdateHousingPreferenceUseCase {
    func execute(
        current: HousingPreference,
        budgetMin: Double,
        budgetMax: Double,
        preferredLocations: [String],
        preferredRoomType: RoomType,
        requiresPetFriendly: Bool
    ) throws -> UpdateHousingPreferenceOutcome {
        guard let range = BudgetRange(min: budgetMin, max: budgetMax) else {
            throw UpdateHousingPreferenceError.invalidBudgetRange
        }
        let new = HousingPreference(
            budgetRange: range,
            preferredLocations: preferredLocations,
            preferredRoomType: preferredRoomType,
            requiresPetFriendly: requiresPetFriendly
        )
        return (new == current) ? .unchanged(current) : .updated(new)
    }
}
