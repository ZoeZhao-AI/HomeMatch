import Foundation

/// Represents a valid weekly rent budget range.
/// Business Rule: max must be greater than min, and both must be positive values.
struct BudgetRange {
    let min: Double
    let max: Double

    init?(min: Double, max: Double) {
        guard max > min, min > 0 else { return nil }
        self.min = min
        self.max = max
    }
}

/// Represents a user's housing search criteria — budget, location, and property requirements.
/// Composed inside RoommateProfile (see section 2.6) rather than existing as a
/// free-floating model — this gives it an explicit structural connection.
struct HousingPreference {
    let budgetRange: BudgetRange
    let preferredLocations: [String]
    let preferredRoomType: RoomType
    let requiresPetFriendly: Bool
}
