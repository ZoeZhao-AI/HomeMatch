import Foundation

enum UpdateHousingPreferenceError: Error, LocalizedError {
    case invalidBudgetRange

    var errorDescription: String? {
        switch self {
        case .invalidBudgetRange:
            return "Your maximum budget must be higher than your minimum. Please check and re-enter."
        }
    }
}

struct UpdateHousingPreferenceUseCase {
    func execute(
        current: HousingPreference,
        budgetMin: Double,
        budgetMax: Double,
        preferredLocations: [String],
        preferredRoomType: RoomType,
        requiresPetFriendly: Bool
    ) throws -> HousingPreference {
        guard let range = BudgetRange(min: budgetMin, max: budgetMax) else {
            throw UpdateHousingPreferenceError.invalidBudgetRange
        }
        return HousingPreference(
            budgetRange: range,
            preferredLocations: preferredLocations,
            preferredRoomType: preferredRoomType,
            requiresPetFriendly: requiresPetFriendly
        )
    }
}
