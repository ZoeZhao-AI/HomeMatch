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

    @Environment(\.dismiss) private var dismiss

    // Temporary sample data for Priya Raman — stand-in until wired to a ViewModel.
    private let stats: [Stat] = [
        Stat(label: "BUDGET", value: "$280–340/wk"),
        Stat(label: "SUBURBS", value: "Ultimo +2"),
        Stat(label: "LIFESTYLE", value: "Quiet, tidy")
    ]

    private let factors: [MatchFactor] = [
        MatchFactor(name: "Sleep schedule", percentage: 96, note: "You both wind down before 11pm on weeknights."),
        MatchFactor(name: "Noise tolerance", percentage: 88, note: "Both prefer quiet study evenings, music on low."),
        MatchFactor(name: "Cooking frequency", percentage: 71, note: "She cooks most nights; you cook 2–3 times a week."),
        MatchFactor(name: "Cleanliness", percentage: 91, note: "Both keep shared areas tidy with a weekly clean."),
        MatchFactor(name: "Smoking & pets", percentage: 100, note: "Both non-smokers, both happy to live with a cat.")
    ]

    private let differences = [
        "Priya cooks dinner at home almost every night and would like to share groceries. You said you cook 2–3 times a week and prefer to shop separately — worth agreeing on early.",
        "You are both quiet on weeknights, but she has friends over most Saturdays — worth checking your weekend guest expectations match."
    ]

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
                StripedPhotoPlaceholder(size: 72, cornerRadius: 14)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Priya Raman, 23")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("Master of Data Science · UTS")
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
                Text("92%")
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

            Text("Ranked 1st of 14 profiles in your search. Scored on 5 lifestyle factors plus budget and location overlap.")
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
            ForEach(differences, id: \.self) { paragraph in
                Text(paragraph)
                    .font(.system(size: 13.5))
                    .foregroundStyle(DesignTokens.cautionBody)
                    .fixedSize(horizontal: false, vertical: true)
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
                ConversationView(name: "Priya Raman", matchPercentage: 92)
            } label: {
                Text("Message Priya")
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
    MatchDetailsView()
}
