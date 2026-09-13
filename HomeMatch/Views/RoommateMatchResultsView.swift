import SwiftUI

struct RoommateCandidateCardData: Identifiable {
    let id: String
    let nameAndAge: String
    let occupation: String
    let matchPercentage: Int
    let tags: [String]
    let budgetLabel: String
    let suburbs: String
}

// Temporary sample data — stand-in until wired to MatchRoommatesUseCase.
extension RoommateCandidateCardData {
    static let samples: [RoommateCandidateCardData] = [
        RoommateCandidateCardData(
            id: "priya",
            nameAndAge: "Priya Raman, 23",
            occupation: "Master of Data Science · UTS",
            matchPercentage: 92,
            tags: ["Early riser", "Quiet weeknights", "Cooks daily"],
            budgetLabel: "$280–$340/week",
            suburbs: "Ultimo, Chippendale"
        ),
        RoommateCandidateCardData(
            id: "mei-lin",
            nameAndAge: "Mei-Lin Tran, 21",
            occupation: "Bachelor of Nursing · USYD",
            matchPercentage: 88,
            tags: ["Shift worker", "Very tidy", "Non-smoker"],
            budgetLabel: "$300–$380/week",
            suburbs: "Glebe, Camperdown"
        ),
        RoommateCandidateCardData(
            id: "jordan",
            nameAndAge: "Jordan Alexopoulos, 25",
            occupation: "Graduate accountant · Barangaroo",
            matchPercentage: 81,
            tags: ["Gym mornings", "Guests on weekends", "Has a cat"],
            budgetLabel: "$350–$450/week",
            suburbs: "Pyrmont, Ultimo"
        ),
        RoommateCandidateCardData(
            id: "hannah",
            nameAndAge: "Hannah O'Rourke, 22",
            occupation: "Bachelor of Design · UNSW",
            matchPercentage: 76,
            tags: ["Night owl", "Vegetarian", "Studio at home"],
            budgetLabel: "$260–$320/week",
            suburbs: "Kensington, Randwick"
        )
    ]
}

struct RoommateMatchResultsView: View {
    private let candidates = RoommateCandidateCardData.samples
    private let lifestyleFilters = ["Non-smoker", "Early riser", "Quiet weeknights", "Pet-friendly", "Vegetarian"]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(candidates) { candidate in
                        RoommateCandidateCard(data: candidate)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            lifestyleFilterBar
        }
        .background(DesignTokens.pageBackground)
    }

    // MARK: - Sticky header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best matches for you")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack(spacing: 10) {
                aiRankedBadge
                Text("14 profiles · updated 2 hrs ago")
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
                StripedPhotoPlaceholder(size: 62, cornerRadius: 12)
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
                Button("View match") {
                    // TODO: navigate to MatchDetailsView (Screen 4)
                }
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
