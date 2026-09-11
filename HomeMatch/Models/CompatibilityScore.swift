import Foundation

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

    let conflictPoints: [String]
}
