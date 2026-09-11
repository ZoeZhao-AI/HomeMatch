import Foundation

/// Represents any score that determines whether a candidate
/// (a listing or a person) should be actively recommended to the user.
protocol RecommendationScoring {
    var overallScore: Double { get }
    var isRecommended: Bool { get }
}

/// Represents any domain record that carries a point-in-time creation timestamp,
/// allowing records to be sorted or filtered chronologically.
protocol Timestamped {
    var timestamp: Date { get }
}
