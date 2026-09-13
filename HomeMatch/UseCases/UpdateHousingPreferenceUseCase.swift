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
