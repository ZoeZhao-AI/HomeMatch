import SwiftUI

struct RoommateCandidateCardData: Identifiable {
    let id: String
    let photoName: String?
    let nameAndAge: String
    let occupation: String
    let matchPercentage: Int
    let tags: [String]
    let budgetLabel: String
    let suburbs: String
}

extension RoommateCandidateCardData {
    init(scored: ScoredCandidate) {
        let profile = scored.candidate
        let budget = profile.housingPreference.budgetRange
        self.init(
            id: profile.userID,
            photoName: Self.samplePhotoName(for: profile.userID),
            nameAndAge: "\(profile.displayName), \(profile.age)",
            occupation: profile.occupation,
            matchPercentage: Int(scored.score.overallScore.rounded()),
            tags: profile.lifestyleProfile.displayTags(),
            budgetLabel: "$\(Int(budget.min))–$\(Int(budget.max))/week",
            suburbs: profile.housingPreference.preferredLocations.joined(separator: ", ")
        )
    }

    // Temporary sample photos keyed by user ID, until profilePhotoURL is backed by real images.
    static func samplePhotoName(for userID: String) -> String? {
        [
            "priya": "avatarPriya",
            "mei-lin": "avatarMeiLin",
            "jordan": "avatarJordan",
            "hannah": "avatarHannah"
        ][userID]
    }
}

extension LifestyleProfile {
    /// Short card tags: values that stand out from typical defaults come first,
    /// then common traits fill any remaining slots.
    func displayTags(limit: Int = 3) -> [String] {
        let distinctive: [String?] = [
            {
                switch sleepSchedule {
                case .veryEarly: return "Very early riser"
                case .early: return "Early riser"
                case .moderate: return nil
                case .late: return "Night owl"
                case .veryLate: return "Very late nights"
                case .flexible: return "Flexible hours"
                }
            }(),
            {
                switch noiseTolerance.dailyNoiseLevel {
                case .veryQuiet: return "Quiet home"
                case .moderate: return nil
                case .livelyOK: return "Lively home"
                }
            }(),
            {
                switch noiseTolerance.guestFrequency {
                case .rarely: return "Rarely has guests"
                case .occasionally: return nil
                case .frequently: return "Frequent guests"
                }
            }(),
            {
                switch cookingFrequency {
                case .rarely: return "Rarely cooks"
                case .occasionally: return nil
                case .daily: return "Cooks daily"
                }
            }(),
            {
                switch cleanlinessLevel {
                case .relaxed: return "Relaxed about mess"
                case .tidy: return nil
                case .veryOrganised: return "Very tidy"
                }
            }(),
            isSmoker ? "Smoker" : nil,
            hasPets ? "Has pets" : nil
        ]
        let common: [String?] = [
            isSmoker ? nil : "Non-smoker",
            cleanlinessLevel == .tidy ? "Tidy" : nil,
            sleepSchedule == .moderate ? "Regular hours" : nil,
            noiseTolerance.dailyNoiseLevel == .moderate ? "Some noise OK" : nil,
            cookingFrequency == .occasionally ? "Cooks sometimes" : nil
        ]
        return Array((distinctive + common).compactMap { $0 }.prefix(limit))
    }
}

struct RoommateMatchResultsView: View {
    @StateObject private var viewModel: RoommatesViewModel
    @State private var showAll = false

    private let lifestyleFilters = ["Non-smoker", "Early riser", "Quiet weeknights", "Pet-friendly", "Vegetarian"]

    @MainActor
    init(viewModel: RoommatesViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? .mock())
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    switch viewModel.state {
                    case .loading:
                        ProgressView()
                            .tint(DesignTokens.primary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    case .noCandidatesAvailable:
                        emptyState(message: "No roommate profiles are available right now. Please check back soon.")
                    case .loaded(let recommended, let all):
                        // Business rule: below-60% candidates stay hidden until the user opts into "Show all".
                        let visible = showAll ? all : recommended

                        if all.count > recommended.count {
                            showAllRow(recommendedCount: recommended.count, totalCount: all.count)
                        }

                        if visible.isEmpty {
                            emptyState(message: "No strong matches yet. Tap Show all to see every profile, or try updating your lifestyle preferences.")
                        } else {
                            ForEach(visible) { scored in
                                NavigationLink {
                                    MatchDetailsView(
                                        candidate: scored.candidate,
                                        score: scored.score,
                                        rank: (all.firstIndex { $0.id == scored.id } ?? 0) + 1,
                                        totalCandidates: all.count
                                    )
                                } label: {
                                    RoommateCandidateCard(data: RoommateCandidateCardData(scored: scored))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            lifestyleFilterBar
        }
        .background(DesignTokens.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.load()
        }
    }

    private var profileCountLabel: String {
        switch viewModel.state {
        case .loading: return "Finding matches…"
        case .noCandidatesAvailable: return "0 profiles"
        case .loaded(_, let all): return all.count == 1 ? "1 profile" : "\(all.count) profiles"
        }
    }

    private func showAllRow(recommendedCount: Int, totalCount: Int) -> some View {
        HStack {
            Text(showAll ? "Showing all \(totalCount) profiles" : "Showing \(recommendedCount) recommended")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textSecondary)
            Spacer(minLength: 8)
            Button(showAll ? "Recommended only" : "Show all (\(totalCount))") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAll.toggle()
                }
            }
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(DesignTokens.primary)
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(DesignTokens.textTertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
    }

    // MARK: - Sticky header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best matches for you")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack(spacing: 10) {
                aiRankedBadge
                Text(profileCountLabel)
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.textBody)
            }

            searchAndFiltersRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)
        }
    }

    private var aiRankedBadge: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(DesignTokens.primary)
                .frame(width: 6, height: 6)
                .rotationEffect(.degrees(45))
            Text("AI ranked")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(DesignTokens.tagBackground)
        .clipShape(Capsule())
    }

    private var searchAndFiltersRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 18))
                .foregroundStyle(DesignTokens.textSecondary)
            Text("Search & Filters")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.textSecondary)
            Spacer()
            Button("Edit") {
                // TODO: open filters
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(DesignTokens.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(DesignTokens.searchFieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Lifestyle filter bar

    private var lifestyleFilterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FILTER BY LIFESTYLE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lifestyleFilters, id: \.self) { filter in
                        Text(filter)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DesignTokens.textBody)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(DesignTokens.tagBackground)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
        .background(DesignTokens.cardBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)
        }
    }
}

// MARK: - Candidate card

struct RoommateCandidateCard: View {
    let data: RoommateCandidateCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PhotoOrPlaceholder(data.photoName, size: 62, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.nameAndAge)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text(data.occupation)
                        .font(.system(size: 13.5))
                        .foregroundStyle(DesignTokens.textBody)
                }
                Spacer(minLength: 8)
                RoommateMatchBadge(percentage: data.matchPercentage)
            }

            FlowLayout(spacing: 6) {
                ForEach(data.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(DesignTokens.textBody)
                        .fixedSize()
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(DesignTokens.tagBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.tagCornerRadius))
                }
            }

            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)

            HStack {
                Text("\(data.budgetLabel) · \(data.suburbs)")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.textBody)
                    .lineLimit(1)
                Spacer(minLength: 8)
                // Plain text: the whole card is the NavigationLink, so a nested
                // Button here would swallow the tap.
                Text("View match")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(DesignTokens.primary)
            }
        }
        .padding(16)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
        .cardShadow()
    }
}

struct RoommateMatchBadge: View {
    let percentage: Int

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(DesignTokens.badgeForeground)
                .frame(width: 6, height: 6)
            Text("\(percentage)%")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DesignTokens.badgeForeground)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(DesignTokens.badgeBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Photo with placeholder fallback

/// Shows the named asset image, or StripedPhotoPlaceholder when there is no name or no such asset.
struct PhotoOrPlaceholder: View {
    let imageName: String?
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    /// Square photo.
    init(_ imageName: String?, size: CGFloat, cornerRadius: CGFloat) {
        self.imageName = imageName
        self.width = size
        self.height = size
        self.cornerRadius = cornerRadius
    }

    /// Fills the available width at a fixed height.
    init(_ imageName: String?, height: CGFloat, cornerRadius: CGFloat = 0) {
        self.imageName = imageName
        self.width = nil
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        if let imageName, UIImage(named: imageName) != nil {
            // Sized container + overlay keeps scaledToFill from widening the layout.
            Color.clear
                .frame(width: width, height: height)
                .frame(maxWidth: width == nil ? .infinity : nil)
                .overlay {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else if let width {
            StripedPhotoPlaceholder(size: width, cornerRadius: cornerRadius)
        } else {
            StripedPhotoPlaceholder(height: height, cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Photo placeholder (diagonal stripes)

struct StripedPhotoPlaceholder: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    /// Square placeholder.
    init(size: CGFloat, cornerRadius: CGFloat) {
        self.width = size
        self.height = size
        self.cornerRadius = cornerRadius
    }

    /// Fills the available width at a fixed height.
    init(height: CGFloat, cornerRadius: CGFloat = 0) {
        self.width = nil
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Canvas { context, canvasSize in
            context.fill(
                Path(CGRect(origin: .zero, size: canvasSize)),
                with: .color(DesignTokens.tagBackground)
            )
            var stripes = Path()
            let spacing: CGFloat = 8
            var x = -canvasSize.height
            while x < canvasSize.width {
                stripes.move(to: CGPoint(x: x, y: canvasSize.height))
                stripes.addLine(to: CGPoint(x: x + canvasSize.height, y: 0))
                x += spacing
            }
            context.stroke(stripes, with: .color(DesignTokens.primary.opacity(0.12)), lineWidth: 3)
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    RoommateMatchResultsView()
}
