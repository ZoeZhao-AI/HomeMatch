import SwiftUI

struct ListingDetailView: View {
    private struct DetailRow: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    private struct Facility: Identifiable {
        let name: String
        let isAvailable: Bool
        var id: String { name }
    }

    // Temporary sample data — stand-in until wired to a HousingListing.
    private let tags = ["Private room", "Fully furnished", "Pet-friendly"]

    private let details: [DetailRow] = [
        DetailRow(label: "Room type", value: "Private room in 3-bed terrace"),
        DetailRow(label: "Furnished", value: "Yes — bed, desk, wardrobe"),
        DetailRow(label: "Bond", value: "$1,800 (4 weeks)"),
        DetailRow(label: "Minimum stay", value: "6 months"),
        DetailRow(label: "Available from", value: "22 Sept 2026")
    ]

    private let facilities: [Facility] = [
        Facility(name: "WiFi (NBN 100)", isAvailable: true),
        Facility(name: "Internal laundry", isAvailable: true),
        Facility(name: "Off-street parking", isAvailable: true),
        Facility(name: "Dishwasher", isAvailable: true),
        Facility(name: "Air conditioning", isAvailable: true),
        Facility(name: "Shared courtyard", isAvailable: true),
        Facility(name: "No pool", isAvailable: false),
        Facility(name: "No gym", isAvailable: false)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    StripedPhotoPlaceholder(height: 260)

                    VStack(alignment: .leading, spacing: 28) {
                        summary
                        propertyDetailsSection
                        facilitiesSection
                        listedBySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }

            bottomBar
        }
        .background(DesignTokens.pageBackground)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$450")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("/week")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            Text("42 Turner St, Redfern NSW 2016")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("12 min to UTS Broadway · 4 min walk to Redfern Station")
                .font(.system(size: 13.5))
                .foregroundStyle(DesignTokens.textBody)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(DesignTokens.textBody)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DesignTokens.tagBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.tagCornerRadius))
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Property details

    private var propertyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Property details")

            VStack(spacing: 0) {
                ForEach(Array(details.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(DesignTokens.divider.opacity(0.5))
                            .frame(height: 1)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(row.label)
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.textSecondary)
                            .fixedSize()
                        Spacer(minLength: 0)
                        Text(row.value)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 16)
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
            .cardShadow()
        }
    }

    // MARK: - Facilities

    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Facilities")

            LazyVGrid(
                columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(facilities) { facility in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle()
                            .fill(facility.isAvailable ? DesignTokens.primary : DesignTokens.disabledText)
                            .frame(width: 7, height: 7)
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                        Text(facility.name)
                            .font(.system(size: 14))
                            .foregroundStyle(facility.isAvailable ? DesignTokens.textBody : DesignTokens.disabledText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
            .cardShadow()
        }
    }

    // MARK: - Listed by

    private var listedBySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Listed by")

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    StripedPhotoPlaceholder(size: 48, cornerRadius: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Daniel Nguyen")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(DesignTokens.textPrimary)
                            Text("AGENT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(DesignTokens.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(DesignTokens.tagBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        Text("Inner West Realty · Licence 10098221")
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.textBody)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Usually replies within 4 hours")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                Button {
                    // TODO: open conversation with agent
                } label: {
                    Text("Message")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignTokens.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignTokens.primary, lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
            .cardShadow()
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        NavigationLink {
            ScheduleViewingView()
        } label: {
            Text("Schedule a viewing")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.primaryButtonHeight)
                .background(DesignTokens.primary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DesignTokens.cardBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(DesignTokens.textPrimary)
    }
}

#Preview {
    ListingDetailView()
}
