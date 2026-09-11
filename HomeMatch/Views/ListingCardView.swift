import SwiftUI

struct ListingCardData: Identifiable {
    let id = UUID()
    let matchPercentage: Int
    let weeklyRent: Int
    let roomType: String
    let propertyType: String
    let address: String
    let commuteInfo: String
    let isFurnished: Bool
    let isPetFriendly: Bool
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
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.35))
                .frame(height: 180)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignTokens.textTertiary)
                )
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

            Text("\(data.roomType) · \(data.propertyType)")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textBody)

            Text(data.address)
                .font(.footnote)
                .foregroundStyle(DesignTokens.textSecondary)

            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                Text(data.commuteInfo)
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
        matchPercentage: 94,
        weeklyRent: 450,
        roomType: "Private Room",
        propertyType: "Apartment",
        address: "42 Broadway St, Ultimo NSW 2007",
        commuteInfo: "8 min walk to UTS",
        isFurnished: true,
        isPetFriendly: true
    ))
    .padding()
    .background(DesignTokens.pageBackground)
}
