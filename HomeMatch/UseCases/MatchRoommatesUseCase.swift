import Foundation

struct MatchRoommatesUseCase {
    func execute(
        currentUser: LifestyleProfile,
        candidates: [RoommateProfile]
    ) -> [(candidate: RoommateProfile, score: CompatibilityScore)] {
        candidates
            .map { candidate in
                (candidate: candidate, score: score(for: candidate, against: currentUser))
            }
            .sorted { $0.score.overallScore > $1.score.overallScore }
    }

    private func score(for candidate: RoommateProfile, against user: LifestyleProfile) -> CompatibilityScore {
        CompatibilityScore(
            candidateID: candidate.userID,
            sleepScheduleMatchScore: sleepScore(user.sleepSchedule, candidate.lifestyleProfile.sleepSchedule),
            noiseToleranceMatchScore: noiseScore(user.noiseTolerance, candidate.lifestyleProfile.noiseTolerance),
            cookingFrequencyMatchScore: cookingScore(user.cookingFrequency, candidate.lifestyleProfile.cookingFrequency),
            cleanlinessMatchScore: cleanlinessScore(user.cleanlinessLevel, candidate.lifestyleProfile.cleanlinessLevel),
            smokingPetsMatchScore: smokingPetsScore(
                userSmoker: user.isSmoker, userHasPets: user.hasPets,
                candidateSmoker: candidate.lifestyleProfile.isSmoker,
                candidateHasPets: candidate.lifestyleProfile.hasPets
            ),
            conflictPoints: []
        )
    }

    // Sub-score helpers

    private func sleepScore(_ a: SleepSchedule, _ b: SleepSchedule) -> Double {
        // .flexible pairs perfectly with anyone
        guard let ai = sleepOrdinal(a), let bi = sleepOrdinal(b) else { return 100 }
        return ordinalScore(ai, bi, steps: 4)
    }

    private func noiseScore(_ a: NoiseTolerance, _ b: NoiseTolerance) -> Double {
        let level = ordinalScore(
            noiseLevelOrdinal(a.dailyNoiseLevel),
            noiseLevelOrdinal(b.dailyNoiseLevel),
            steps: 2
        )
        let guests = ordinalScore(
            guestFrequencyOrdinal(a.guestFrequency),
            guestFrequencyOrdinal(b.guestFrequency),
            steps: 2
        )
        return (level + guests) / 2
    }

    private func cookingScore(_ a: CookingFrequency, _ b: CookingFrequency) -> Double {
        ordinalScore(cookingFrequencyOrdinal(a), cookingFrequencyOrdinal(b), steps: 2)
    }

    private func cleanlinessScore(_ a: CleanlinessLevel, _ b: CleanlinessLevel) -> Double {
        ordinalScore(cleanlinessOrdinal(a), cleanlinessOrdinal(b), steps: 2)
    }

    private func smokingPetsScore(
        userSmoker: Bool, userHasPets: Bool,
        candidateSmoker: Bool, candidateHasPets: Bool
    ) -> Double {
        var matches = 0
        if userSmoker == candidateSmoker { matches += 1 }
        if userHasPets == candidateHasPets { matches += 1 }
        return Double(matches) * 50
    }

    // Ordinal mappings

    private func ordinalScore(_ a: Int, _ b: Int, steps: Int) -> Double {
        let distance = abs(a - b)
        return max(0, 100 - Double(distance) * (100.0 / Double(steps)))
    }

    private func sleepOrdinal(_ s: SleepSchedule) -> Int? {
        switch s {
        case .veryEarly: return 0
        case .early: return 1
        case .moderate: return 2
        case .late: return 3
        case .veryLate: return 4
        case .flexible: return nil
        }
    }

    private func noiseLevelOrdinal(_ n: DailyNoiseLevel) -> Int {
        switch n {
        case .veryQuiet: return 0
        case .moderate: return 1
        case .livelyOK: return 2
        }
    }

    private func guestFrequencyOrdinal(_ g: GuestFrequency) -> Int {
        switch g {
        case .rarely: return 0
        case .occasionally: return 1
        case .frequently: return 2
        }
    }

    private func cookingFrequencyOrdinal(_ c: CookingFrequency) -> Int {
        switch c {
        case .rarely: return 0
        case .occasionally: return 1
        case .daily: return 2
        }
    }

    private func cleanlinessOrdinal(_ c: CleanlinessLevel) -> Int {
        switch c {
        case .relaxed: return 0
        case .tidy: return 1
        case .veryOrganised: return 2
        }
    }
}
