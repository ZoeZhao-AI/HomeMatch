import SwiftUI

struct HomeView: View {
    private let sampleListings: [ListingCardData] = [
        ListingCardData(
            matchPercentage: 94,
            weeklyRent: 450,
            roomType: "Private Room",
            propertyType: "Apartment",
            address: "42 Broadway St, Ultimo NSW 2007",
            commuteInfo: "8 min walk to UTS",
            isFurnished: true,
            isPetFriendly: true
        ),
        ListingCardData(
            matchPercentage: 88,
            weeklyRent: 380,
            roomType: "Private Room",
            propertyType: "Share House",
            address: "18 Regent St, Chippendale NSW 2008",
            commuteInfo: "12 min walk to UTS",
            isFurnished: true,
            isPetFriendly: false
        ),
        ListingCardData(
            matchPercentage: 76,
            weeklyRent: 520,
            roomType: "Entire Place",
            propertyType: "Studio",
            address: "220 Cleveland St, Redfern NSW 2016",
            commuteInfo: "15 min bus to UTS",
            isFurnished: false,
            isPetFriendly: true
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                headline
                aiMatchButton
                recommendedSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(DesignTokens.pageBackground)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Location")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.textTertiary)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(DesignTokens.primary)
                    Text("Sydney · Inner West")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                }
            }
            Spacer()
            Image(systemName: "person.crop.circle")
                .font(.system(size: 32))
                .foregroundStyle(DesignTokens.textBody)
        }
    }

    private var headline: some View {
        Text("Find a place that fits your life")
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(DesignTokens.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var aiMatchButton: some View {
        Button {
            // TODO: navigate to AI Match preferences
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Match")
                        .font(.headline)
                    Text("Tell us what you need")
                        .font(.subheadline)
                        .opacity(0.85)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.primaryButtonHeight + 12)
            .foregroundStyle(.white)
            .background(DesignTokens.primary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended homes")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Spacer()
                Button("See all") {
                    // TODO: navigate to full list
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DesignTokens.primary)
            }
            ForEach(sampleListings) { listing in
                ListingCardView(data: listing)
            }
        }
    }
}

#Preview {
    HomeView()
}
