import Foundation
import Combine

struct ScoredCandidate: Identifiable {
    let candidate: RoommateProfile
    let score: CompatibilityScore
    var id: String { candidate.userID }
}

@MainActor
final class RoommatesViewModel: ObservableObject {
    enum State {
        case loading
        case loaded(recommended: [ScoredCandidate], all: [ScoredCandidate])
        case noCandidatesAvailable
    }

    @Published private(set) var state: State = .loading

    private let useCase: MatchRoommatesUseCase
    private let currentUser: LifestyleProfile
    private let candidates: [RoommateProfile]

    init(
        currentUser: LifestyleProfile,
        candidates: [RoommateProfile],
        useCase: MatchRoommatesUseCase = MatchRoommatesUseCase()
    ) {
        self.currentUser = currentUser
        self.candidates = candidates
        self.useCase = useCase
    }

    func load() {
        state = .loading
        guard !candidates.isEmpty else {
            state = .noCandidatesAvailable
            return
        }
        let all = useCase.execute(currentUser: currentUser, candidates: candidates)
            .map { ScoredCandidate(candidate: $0.candidate, score: $0.score) }
        let recommended = all.filter { $0.score.isRecommended }
        state = .loaded(recommended: recommended, all: all)
    }
}

// Temporary sample data — stand-in until a Repository is introduced.
extension RoommatesViewModel {
    static func mock() -> RoommatesViewModel {
        RoommatesViewModel(currentUser: sampleCurrentUser, candidates: sampleCandidates)
    }

    /// Emily's lifestyle — mirrors PreferencesViewModel.mock() so both screens agree.
    static let sampleCurrentUser = LifestyleProfile(
        userID: "current",
        sleepSchedule: .moderate,
        noiseTolerance: NoiseTolerance(dailyNoiseLevel: .moderate, guestFrequency: .occasionally),
        cookingFrequency: .occasionally,
        isSmoker: false,
        hasPets: false,
        cleanlinessLevel: .tidy
    )

    // Lifestyles are chosen so MatchRoommatesUseCase scores them against sampleCurrentUser at
    // 92.5 (Priya), 87.5 (Mei-Lin), 81.25 (Jordan) and 76.25 (Hannah).
    static let sampleCandidates: [RoommateProfile] = [
        RoommateProfile(
            userID: "priya",
            displayName: "Priya Raman",
            age: 23,
            occupation: "Master of Data Science · UTS",
            profilePhotoURL: nil,
            lifestyleProfile: LifestyleProfile(
                userID: "priya",
                sleepSchedule: .moderate,
                noiseTolerance: NoiseTolerance(dailyNoiseLevel: .moderate, guestFrequency: .occasionally),
                cookingFrequency: .daily,
                isSmoker: false,
                hasPets: false,
                cleanlinessLevel: .tidy
            ),
            housingPreference: HousingPreference(
                budgetRange: BudgetRange(min: 280, max: 340)!,
                preferredLocations: ["Ultimo", "Chippendale"],
                preferredRoomType: .privateRoom,
                requiresPetFriendly: false
            ),
            shortBio: nil
        )!,
        RoommateProfile(
            userID: "mei-lin",
            displayName: "Mei-Lin Tran",
            age: 21,
            occupation: "Bachelor of Nursing · USYD",
            profilePhotoURL: nil,
            lifestyleProfile: LifestyleProfile(
                userID: "mei-lin",
                sleepSchedule: .flexible,
                noiseTolerance: NoiseTolerance(dailyNoiseLevel: .veryQuiet, guestFrequency: .rarely),
                cookingFrequency: .occasionally,
                isSmoker: false,
                hasPets: false,
                cleanlinessLevel: .tidy
            ),
            housingPreference: HousingPreference(
                budgetRange: BudgetRange(min: 300, max: 380)!,
                preferredLocations: ["Glebe", "Camperdown"],
                preferredRoomType: .privateRoom,
                requiresPetFriendly: false
            ),
            shortBio: nil
        )!,
        RoommateProfile(
            userID: "jordan",
            displayName: "Jordan Alexopoulos",
            age: 25,
            occupation: "Graduate accountant · Barangaroo",
            profilePhotoURL: nil,
            lifestyleProfile: LifestyleProfile(
                userID: "jordan",
                sleepSchedule: .early,
                noiseTolerance: NoiseTolerance(dailyNoiseLevel: .livelyOK, guestFrequency: .frequently),
                cookingFrequency: .occasionally,
                isSmoker: false,
                hasPets: false,
                cleanlinessLevel: .tidy
            ),
            housingPreference: HousingPreference(
                budgetRange: BudgetRange(min: 350, max: 450)!,
                preferredLocations: ["Pyrmont", "Ultimo"],
                preferredRoomType: .privateRoom,
                requiresPetFriendly: false
            ),
            shortBio: nil
        )!,
        RoommateProfile(
            userID: "hannah",
            displayName: "Hannah O'Rourke",
            age: 22,
            occupation: "Bachelor of Design · UNSW",
            profilePhotoURL: nil,
            lifestyleProfile: LifestyleProfile(
                userID: "hannah",
                sleepSchedule: .late,
                noiseTolerance: NoiseTolerance(dailyNoiseLevel: .moderate, guestFrequency: .occasionally),
                cookingFrequency: .occasionally,
                isSmoker: false,
                hasPets: true,
                cleanlinessLevel: .relaxed
            ),
            housingPreference: HousingPreference(
                budgetRange: BudgetRange(min: 260, max: 320)!,
                preferredLocations: ["Kensington", "Randwick"],
                preferredRoomType: .privateRoom,
                requiresPetFriendly: true
            ),
            shortBio: nil
        )!
    ]
}
