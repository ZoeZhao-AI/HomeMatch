import Foundation

/// Represents the business operation of comparing the current user's `LifestyleProfile` with each
/// candidate roommate, producing a `CompatibilityScore` for every candidate, ranked from most to
/// least compatible.
/// Each lifestyle factor is scored by how close the two answers are — identical answers score
/// highest, and a flexible sleep schedule suits anyone. Smoking and pets each count for half of
/// their factor's score when the two people match.
/// Business Rule: every candidate is returned, including those below 60% — whether a candidate is
/// actively recommended is decided by `CompatibilityScore`, so the user can still choose "Show all".
/// Business Rule: every meaningful lifestyle difference is recorded as a plain-English conflict
/// point (for example, "You rarely cook; they cook daily."). A factor counts as a difference when
/// it scores below 60%, and any difference in smoking or pets always counts. These points must
/// always be shown to the user, never hidden.
struct MatchRoommatesUseCase {
    private static let conflictThreshold: Double = 60

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
            conflictPoints: conflicts(user: user, candidate: candidate.lifestyleProfile)
        )
    }

    private func conflicts(user: LifestyleProfile, candidate: LifestyleProfile) -> [String] {
        var points: [String] = []

        if sleepScore(user.sleepSchedule, candidate.sleepSchedule) < Self.conflictThreshold {
            points.append("You \(sleepLabel(user.sleepSchedule)); they \(sleepLabel(candidate.sleepSchedule)).")
        }

        let levelScore = ordinalScore(
            noiseLevelOrdinal(user.noiseTolerance.dailyNoiseLevel),
            noiseLevelOrdinal(candidate.noiseTolerance.dailyNoiseLevel),
            steps: 2
        )
        if levelScore < Self.conflictThreshold {
            points.append("You \(noiseLevelLabel(user.noiseTolerance.dailyNoiseLevel)); they \(noiseLevelLabel(candidate.noiseTolerance.dailyNoiseLevel)).")
        }

        let guestsScore = ordinalScore(
            guestFrequencyOrdinal(user.noiseTolerance.guestFrequency),
            guestFrequencyOrdinal(candidate.noiseTolerance.guestFrequency),
            steps: 2
        )
        if guestsScore < Self.conflictThreshold {
            points.append("You \(guestLabel(user.noiseTolerance.guestFrequency)); they \(guestLabel(candidate.noiseTolerance.guestFrequency)).")
        }

        if cookingScore(user.cookingFrequency, candidate.cookingFrequency) < Self.conflictThreshold {
            points.append("You \(cookingLabel(user.cookingFrequency)); they \(cookingLabel(candidate.cookingFrequency)).")
        }

        if cleanlinessScore(user.cleanlinessLevel, candidate.cleanlinessLevel) < Self.conflictThreshold {
            points.append("You \(cleanlinessLabel(user.cleanlinessLevel)); they \(cleanlinessLabel(candidate.cleanlinessLevel)).")
        }

        if user.isSmoker != candidate.isSmoker {
            points.append("You \(smokerLabel(user.isSmoker)); they \(smokerLabel(candidate.isSmoker)).")
        }

        if user.hasPets != candidate.hasPets {
            points.append("You \(petsLabel(user.hasPets)); they \(petsLabel(candidate.hasPets)).")
        }

        return points
    }

    // Human-readable labels — designed to fit the template "You X; they Y."

    private func sleepLabel(_ s: SleepSchedule) -> String {
        switch s {
        case .veryEarly: return "sleep very early (before 9pm)"
        case .early: return "sleep early (9pm–11pm)"
        case .moderate: return "sleep at moderate hours (11pm–1am)"
        case .late: return "sleep late (1am–3am)"
        case .veryLate: return "sleep very late (after 3am)"
        case .flexible: return "have a flexible sleep schedule"
        }
    }

    private func noiseLevelLabel(_ n: DailyNoiseLevel) -> String {
        switch n {
        case .veryQuiet: return "prefer very quiet spaces"
        case .moderate: return "are okay with moderate noise"
        case .livelyOK: return "enjoy lively environments"
        }
    }

    private func guestLabel(_ g: GuestFrequency) -> String {
        switch g {
        case .rarely: return "rarely have guests over"
        case .occasionally: return "occasionally have guests over"
        case .frequently: return "have guests over frequently"
        }
    }

    private func cookingLabel(_ c: CookingFrequency) -> String {
        switch c {
        case .rarely: return "rarely cook"
        case .occasionally: return "cook occasionally"
        case .daily: return "cook daily"
        }
    }

    private func cleanlinessLabel(_ c: CleanlinessLevel) -> String {
        switch c {
        case .relaxed: return "are relaxed about cleanliness"
        case .tidy: return "keep things tidy"
        case .veryOrganised: return "keep things very organised"
        }
    }

    private func smokerLabel(_ isSmoker: Bool) -> String {
        isSmoker ? "smoke" : "don't smoke"
    }

    private func petsLabel(_ hasPets: Bool) -> String {
        hasPets ? "have pets" : "don't have pets"
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
