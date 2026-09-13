import SwiftUI

struct ListingCardData: Identifiable {
    let id: String
    let matchPercentage: Int
    let weeklyRent: Int
    let roomTypeLabel: String
    let address: String
    let minStayMonths: Int
    let isFurnished: Bool
    let isPetFriendly: Bool
    var photoName: String? = nil
}

extension ListingCardData {
    init(scored: ScoredListing) {
        self.init(
            id: scored.listing.listingID,
            matchPercentage: Int(scored.score.overallScore.rounded()),
            weeklyRent: Int(scored.listing.weeklyRent.rounded()),
            roomTypeLabel: Self.label(for: scored.listing.roomType),
            address: scored.listing.location,
            minStayMonths: scored.listing.minStayDuration,
            isFurnished: scored.listing.isFurnished,
            isPetFriendly: scored.listing.isPetFriendly,
            photoName: Self.samplePhotoNames[scored.listing.listingID]
        )
    }

    // Temporary sample photos keyed by listing ID; listings without one fall back to the placeholder.
    // L3 is 42 Turner St, which uses listing1 to match ListingDetailView and ConversationView.
    private static let samplePhotoNames: [String: String] = [
        "L1": "listing3",
        "L2": "listing2",
        "L3": "listing1"
    ]

    private static func label(for roomType: RoomType) -> String {
        switch roomType {
        case .privateRoom: return "Private Room"
        case .sharedRoom: return "Shared Room"
        case .entirePlace: return "Entire Place"
        }
    }
}

struct ListingCardView: View {
    let data: ListingCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo
            info
        }
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
        .cardShadow()
    }

    private var photo: some View {
        ZStack(alignment: .topTrailing) {
            PhotoOrPlaceholder(data.photoName, height: 180)
            MatchBadge(percentage: data.matchPercentage)
                .padding(12)
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$\(data.weeklyRent)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("/week")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            Text(data.roomTypeLabel)
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textBody)

            Text(data.address)
                .font(.footnote)
                .foregroundStyle(DesignTokens.textSecondary)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("Min. \(data.minStayMonths) months")
            }
            .font(.footnote)
            .foregroundStyle(DesignTokens.textSecondary)

            HStack(spacing: 8) {
                if data.isFurnished { ListingTagChip(text: "Furnished") }
                if data.isPetFriendly { ListingTagChip(text: "Pet-friendly") }
            }
            .padding(.top, 4)
        }
        .padding(16)
    }
}

struct MatchBadge: View {
    let percentage: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DesignTokens.badgeForeground)
                .frame(width: 6, height: 6)
            Text("\(percentage)% Match")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignTokens.badgeForeground)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignTokens.badgeBackground)
        .clipShape(Capsule())
    }
}

struct ListingTagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(DesignTokens.textBody)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(DesignTokens.tagBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.tagCornerRadius))
    }
}

#Preview {
    ListingCardView(data: ListingCardData(
        id: "preview",
        matchPercentage: 94,
        weeklyRent: 450,
        roomTypeLabel: "Private Room",
        address: "42 Broadway St, Ultimo NSW 2007",
        minStayMonths: 6,
        isFurnished: true,
        isPetFriendly: true
    ))
    .padding()
    .background(DesignTokens.pageBackground)
}
