import Foundation

/// Represents the compatibility between the current user and a candidate roommate,
/// based on their respective LifestyleProfiles.
/// Business Rule: candidates scoring below 60% overall are not actively recommended,
/// but remain visible if the user chooses "Show all".
/// Business Rule: any lifestyle conflict points must be explicitly surfaced, not hidden.
struct CompatibilityScore {
    let candidateID: String
    let sleepScheduleMatchScore: Double      // weight 25%
    let noiseToleranceMatchScore: Double     // weight 25%
    let cookingFrequencyMatchScore: Double   // weight 15%
    let cleanlinessMatchScore: Double        // weight 20%
    let smokingPetsMatchScore: Double        // weight 15%

    var overallScore: Double {
        (sleepScheduleMatchScore * 0.25)
        + (noiseToleranceMatchScore * 0.25)
        + (cookingFrequencyMatchScore * 0.15)
        + (cleanlinessMatchScore * 0.20)
        + (smokingPetsMatchScore * 0.15)
    }

    var isRecommended: Bool {
        overallScore >= 60.0
    }

    /// Corresponds to "Potential Differences" in the UI. Must always be shown
    /// in the Match Details screen — never hidden, even when overallScore is high.
    let conflictPoints: [String]
}
