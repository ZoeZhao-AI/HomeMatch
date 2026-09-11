import Foundation

/// Represents how well a specific housing listing matches a user's housing preferences.
/// Business Rule: listings scoring below 60% are not actively recommended,
/// but remain visible if the user chooses "Show all".
struct ListingMatchScore: RecommendationScoring {
    let listingID: String
    let budgetMatchScore: Double          // weight 35%
    let locationMatchScore: Double        // weight 30%
    let roomTypeMatchScore: Double        // weight 20%
    let facilitiesMatchScore: Double      // weight 15%

    var overallScore: Double {
        (budgetMatchScore * 0.35)
        + (locationMatchScore * 0.30)
        + (roomTypeMatchScore * 0.20)
        + (facilitiesMatchScore * 0.15)
    }

    var isRecommended: Bool {
        overallScore >= 60.0
    }
}
