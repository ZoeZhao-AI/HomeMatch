import XCTest
@testable import HomeMatch

final class MatchRoommatesUseCaseTests: XCTestCase {

    private let sut = MatchRoommatesUseCase()

    // MARK: - Fixtures

    private func makeLifestyle(
        userID: String = "U",
        sleep: SleepSchedule = .moderate,
        noiseLevel: DailyNoiseLevel = .moderate,
        guests: GuestFrequency = .occasionally,
        cooking: CookingFrequency = .occasionally,
        isSmoker: Bool = false,
        hasPets: Bool = false,
        cleanliness: CleanlinessLevel = .tidy
    ) -> LifestyleProfile {
        LifestyleProfile(
            userID: userID,
            sleepSchedule: sleep,
            noiseTolerance: NoiseTolerance(dailyNoiseLevel: noiseLevel, guestFrequency: guests),
            cookingFrequency: cooking,
            isSmoker: isSmoker,
            hasPets: hasPets,
            cleanlinessLevel: cleanliness
        )
    }

    private func makeCandidate(
        userID: String,
        displayName: String = "Candidate",
        lifestyle: LifestyleProfile
    ) -> RoommateProfile {
        RoommateProfile(
            userID: userID,
            displayName: displayName,
            age: 22,
            occupation: "Student",
            profilePhotoURL: nil,
            lifestyleProfile: lifestyle,
            housingPreference: HousingPreference(
                budgetRange: BudgetRange(min: 300, max: 500)!,
                preferredLocations: ["Ultimo"],
                preferredRoomType: .privateRoom,
                requiresPetFriendly: false
            ),
            shortBio: nil
        )!
    }

    // MARK: - 1. Happy path — sorted by score

    func testHappyPath_highCompatibilityCandidateRanksAboveLow() {
        let user = makeLifestyle(userID: "U1")
        let highMatch = makeCandidate(
            userID: "C_high",
            lifestyle: makeLifestyle(userID: "C_high")  // identical to user
        )
        let lowMatch = makeCandidate(
            userID: "C_low",
            lifestyle: makeLifestyle(
                userID: "C_low",
                sleep: .veryLate,
                noiseLevel: .livelyOK,
                guests: .frequently,
                cooking: .daily,
                isSmoker: true,
                hasPets: true,
                cleanliness: .relaxed
            )
        )

        let results = sut.execute(currentUser: user, candidates: [lowMatch, highMatch])

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].candidate.userID, "C_high")
        XCTAssertEqual(results[1].candidate.userID, "C_low")
        XCTAssertGreaterThan(results[0].score.overallScore, results[1].score.overallScore)
        XCTAssertEqual(results[0].score.overallScore, 100, accuracy: 0.001)
    }

    // MARK: - 2. Sleep mismatch → specific conflictPoint

    func testSleepMismatch_conflictPointDescribesBothHabits() {
        let user = makeLifestyle(userID: "U1", sleep: .veryEarly)
        let candidate = makeCandidate(
            userID: "C1",
            lifestyle: makeLifestyle(userID: "C1", sleep: .veryLate)
        )

        let results = sut.execute(currentUser: user, candidates: [candidate])

        let conflictPoints = results[0].score.conflictPoints
        let sleepConflict = conflictPoints.first(where: { $0.contains("sleep") })
        XCTAssertNotNil(sleepConflict, "Expected a sleep-related conflict point")
        XCTAssertTrue(sleepConflict!.contains("before 9pm"),
                      "Expected user's habit (very early / before 9pm) in message; got: \(sleepConflict!)")
        XCTAssertTrue(sleepConflict!.contains("after 3am"),
                      "Expected candidate's habit (very late / after 3am) in message; got: \(sleepConflict!)")
    }

    // MARK: - 3. isRecommended reflects the 60% threshold

    func testIsRecommended_reflectsSixtyPercentThreshold() {
        let user = makeLifestyle(userID: "U1")
        let aboveThreshold = makeCandidate(
            userID: "C_above",
            lifestyle: makeLifestyle(userID: "C_above")  // identical → 100
        )
        let belowThreshold = makeCandidate(
            userID: "C_below",
            lifestyle: makeLifestyle(
                userID: "C_below",
                sleep: .veryLate,
                noiseLevel: .livelyOK,
                guests: .frequently,
                cooking: .daily,
                isSmoker: true,
                hasPets: true,
                cleanliness: .relaxed
            )
        )

        let results = sut.execute(currentUser: user, candidates: [aboveThreshold, belowThreshold])

        let above = results.first(where: { $0.candidate.userID == "C_above" })!
        let below = results.first(where: { $0.candidate.userID == "C_below" })!

        XCTAssertGreaterThanOrEqual(above.score.overallScore, 60)
        XCTAssertTrue(above.score.isRecommended)
        XCTAssertLessThan(below.score.overallScore, 60)
        XCTAssertFalse(below.score.isRecommended)
    }

    // MARK: - 4. Show all — low scorers still returned

    func testLowScoringCandidatesNotFiltered() {
        let user = makeLifestyle(userID: "U1")
        let veryLow = makeCandidate(
            userID: "C_low",
            lifestyle: makeLifestyle(
                userID: "C_low",
                sleep: .veryLate,
                noiseLevel: .livelyOK,
                guests: .frequently,
                cooking: .daily,
                isSmoker: true,
                hasPets: true,
                cleanliness: .relaxed
            )
        )
        let mid = makeCandidate(
            userID: "C_mid",
            lifestyle: makeLifestyle(userID: "C_mid", sleep: .late)  // small mismatch
        )
        let high = makeCandidate(
            userID: "C_high",
            lifestyle: makeLifestyle(userID: "C_high")  // identical
        )

        let results = sut.execute(currentUser: user, candidates: [veryLow, mid, high])

        XCTAssertEqual(results.count, 3)
        XCTAssertFalse(results.last!.score.isRecommended,
                       "Low scorer should still appear in the returned list even when not recommended")
        XCTAssertTrue(results.map { $0.candidate.userID }.contains("C_low"))
    }

    // MARK: - 5. Flexible sleep schedule pairs perfectly with anyone

    func testFlexibleSleepSchedule_scoresFullSleepMatchAgainstAnySchedule() {
        let user = makeLifestyle(userID: "U1", sleep: .flexible)
        let candidate = makeCandidate(
            userID: "C1",
            lifestyle: makeLifestyle(userID: "C1", sleep: .veryLate)
        )

        let results = sut.execute(currentUser: user, candidates: [candidate])

        XCTAssertEqual(results[0].score.sleepScheduleMatchScore, 100, accuracy: 0.001)
        let sleepConflict = results[0].score.conflictPoints.first(where: { $0.contains("sleep") })
        XCTAssertNil(sleepConflict, "Flexible schedule should not produce a sleep conflict; got: \(sleepConflict ?? "")")
    }
}
