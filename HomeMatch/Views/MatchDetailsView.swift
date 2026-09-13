import SwiftUI

struct MatchDetailsView: View {
    private struct MatchFactor: Identifiable {
        let name: String
        let percentage: Int
        let note: String
        var id: String { name }
    }

    private struct Stat: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    let candidate: RoommateProfile
    let score: CompatibilityScore
    let rank: Int
    let totalCandidates: Int

    @Environment(\.dismiss) private var dismiss

    private var lifestyle: LifestyleProfile { candidate.lifestyleProfile }

    private var firstName: String {
        candidate.displayName.split(separator: " ").first.map(String.init) ?? candidate.displayName
    }

    private var matchPercentage: Int { Int(score.overallScore.rounded()) }

    private var photoName: String? { RoommateCandidateCardData.samplePhotoName(for: candidate.userID) }

    private var rankLabel: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale(identifier: "en_AU")
        let ordinal = formatter.string(from: NSNumber(value: rank)) ?? "\(rank)"
        let profiles = totalCandidates == 1 ? "profile" : "profiles"
        return "Ranked \(ordinal) of \(totalCandidates) \(profiles) in your search. Scored on 5 lifestyle factors."
    }

    private var stats: [Stat] {
        let budget = candidate.housingPreference.budgetRange
        let locations = candidate.housingPreference.preferredLocations
        let suburbs: String = {
            guard let first = locations.first else { return "Any" }
            return locations.count > 1 ? "\(first) +\(locations.count - 1)" : first
        }()
        let noise: String = {
            switch lifestyle.noiseTolerance.dailyNoiseLevel {
            case .veryQuiet: return "Quiet"
            case .moderate: return "Some noise"
            case .livelyOK: return "Lively"
            }
        }()
        let cleanliness: String = {
            switch lifestyle.cleanlinessLevel {
            case .relaxed: return "relaxed"
            case .tidy: return "tidy"
            case .veryOrganised: return "very tidy"
            }
        }()
        return [
            Stat(label: "BUDGET", value: "$\(Int(budget.min))–\(Int(budget.max))/wk"),
            Stat(label: "SUBURBS", value: suburbs),
            Stat(label: "LIFESTYLE", value: "\(noise), \(cleanliness)")
        ]
    }

    private var factors: [MatchFactor] {
        let sleep: String = {
            switch lifestyle.sleepSchedule {
            case .veryEarly: return "goes to bed very early"
            case .early: return "is an early riser"
            case .moderate: return "keeps moderate hours"
            case .late: return "is a night owl"
            case .veryLate: return "stays up very late"
            case .flexible: return "has a flexible schedule"
            }
        }()
        let noiseLevel: String = {
            switch lifestyle.noiseTolerance.dailyNoiseLevel {
            case .veryQuiet: return "prefers a very quiet home"
            case .moderate: return "is fine with some noise"
            case .livelyOK: return "enjoys a lively home"
            }
        }()
        let guests: String = {
            switch lifestyle.noiseTolerance.guestFrequency {
            case .rarely: return "rarely has guests over"
            case .occasionally: return "occasionally has guests over"
            case .frequently: return "has guests over often"
            }
        }()
        let cooking: String = {
            switch lifestyle.cookingFrequency {
            case .rarely: return "rarely cooks"
            case .occasionally: return "cooks a few times a week"
            case .daily: return "cooks daily"
            }
        }()
        let cleanliness: String = {
            switch lifestyle.cleanlinessLevel {
            case .relaxed: return "is relaxed about tidiness"
            case .tidy: return "keeps shared areas tidy"
            case .veryOrganised: return "keeps things very organised"
            }
        }()
        let smoking = lifestyle.isSmoker ? "smokes" : "doesn't smoke"
        let pets = lifestyle.hasPets ? "has pets" : "has no pets"
        return [
            MatchFactor(name: "Sleep schedule", percentage: percent(score.sleepScheduleMatchScore), note: "\(firstName) \(sleep)."),
            MatchFactor(name: "Noise tolerance", percentage: percent(score.noiseToleranceMatchScore), note: "\(firstName) \(noiseLevel) and \(guests)."),
            MatchFactor(name: "Cooking frequency", percentage: percent(score.cookingFrequencyMatchScore), note: "\(firstName) \(cooking)."),
            MatchFactor(name: "Cleanliness", percentage: percent(score.cleanlinessMatchScore), note: "\(firstName) \(cleanliness)."),
            MatchFactor(name: "Smoking & pets", percentage: percent(score.smokingPetsMatchScore), note: "\(firstName) \(smoking) and \(pets).")
        ]
    }

    private func percent(_ value: Double) -> Int {
        Int(value.rounded())
    }

    var body: some View {
        VStack(spacing: 0) {
            backHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    profileBlock

                    VStack(alignment: .leading, spacing: 24) {
                        whyYouMatchSection
                        potentialDifferencesCallout
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }

            bottomBar
        }
        .background(DesignTokens.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var backHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Matches")
                        .font(.system(size: 16))
                }
                .foregroundStyle(DesignTokens.primary)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DesignTokens.cardBackground)
    }

    // MARK: - Profile block

    private var profileBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                PhotoOrPlaceholder(photoName, size: 72, cornerRadius: 14)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(candidate.displayName), \(candidate.age)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text(candidate.occupation)
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.textBody)
                    VerifiedBadge()
                        .padding(.top, 4)
                }
            }

            overallMatchCard
            statChips
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.cardBackground)
    }

    private var overallMatchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(matchPercentage)%")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(DesignTokens.matchScoreText)
                Text("OVERALL MATCH")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(DesignTokens.primary)
            }

            Rectangle()
                .fill(DesignTokens.primary.opacity(0.15))
                .frame(height: 1)

            Text(rankLabel)
                .font(.system(size: 12.5))
                .foregroundStyle(DesignTokens.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.tagBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statChips: some View {
        HStack(spacing: 8) {
            ForEach(stats) { stat in
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.label)
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(DesignTokens.textSecondary)
                    Text(stat.value)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Why you match

    private var whyYouMatchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Why you match")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("Compared against your saved lifestyle preferences.")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            VStack(alignment: .leading, spacing: 18) {
                ForEach(factors) { factor in
                    factorRow(factor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
            .cardShadow()
        }
    }

    private func factorRow(_ factor: MatchFactor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(factor.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Spacer()
                Text("\(factor.percentage)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DesignTokens.primary)
            }
            MatchProgressBar(fraction: Double(factor.percentage) / 100)
            Text(factor.note)
                .font(.system(size: 12.5))
                .foregroundStyle(DesignTokens.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Potential differences

    private var potentialDifferencesCallout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignTokens.cautionIcon)
                Text("Potential differences")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DesignTokens.cautionTitle)
            }
            // Business rule: conflict points are always surfaced, never hidden — even for high scores.
            if score.conflictPoints.isEmpty {
                Text("No major lifestyle differences found.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(DesignTokens.cautionBody)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(score.conflictPoints, id: \.self) { point in
                    Text(point)
                        .font(.system(size: 13.5))
                        .foregroundStyle(DesignTokens.cautionBody)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.cautionBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                // TODO: save / shortlist action
            } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignTokens.primary)
                    .frame(width: DesignTokens.primaryButtonHeight, height: DesignTokens.primaryButtonHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius)
                            .stroke(DesignTokens.divider, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ConversationView(name: candidate.displayName, matchPercentage: matchPercentage, avatarImageName: photoName)
            } label: {
                Text("Message \(firstName)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.primaryButtonHeight)
                    .background(DesignTokens.primary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius))
                    .shadow(color: DesignTokens.primary.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DesignTokens.cardBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)
        }
    }
}

struct VerifiedBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DesignTokens.primary)
                .frame(width: 6, height: 6)
            Text("ID & student email verified")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(DesignTokens.tagBackground)
        .clipShape(Capsule())
    }
}

private struct MatchProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignTokens.progressTrack)
                Capsule()
                    .fill(DesignTokens.primary)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 7)
    }
}

#Preview {
    let scored = MatchRoommatesUseCase().execute(
        currentUser: RoommatesViewModel.sampleCurrentUser,
        candidates: RoommatesViewModel.sampleCandidates
    )
    MatchDetailsView(
        candidate: scored[0].candidate,
        score: scored[0].score,
        rank: 1,
        totalCandidates: scored.count
    )
}
