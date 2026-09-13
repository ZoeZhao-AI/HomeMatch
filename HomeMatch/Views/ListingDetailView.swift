import SwiftUI

struct ListingDetailView: View {
    @StateObject private var viewModel: ListingDetailViewModel
    private let photoName: String?

    @MainActor
    init(listing: HousingListing) {
        _viewModel = StateObject(wrappedValue: ListingDetailViewModel(listing: listing))
        photoName = ListingCardData.samplePhotoName(for: listing.listingID)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PhotoOrPlaceholder(photoName, height: 260)

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
                Text(viewModel.rentLabel)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("/week")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            Text(viewModel.address)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.tags, id: \.self) { tag in
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
                ForEach(Array(viewModel.detailRows.enumerated()), id: \.element.id) { index, row in
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

            Group {
                if viewModel.facilityNames.isEmpty {
                    Text("No facilities listed")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                        alignment: .leading,
                        spacing: 12
                    ) {
                        ForEach(viewModel.facilityNames, id: \.self) { name in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Circle()
                                    .fill(DesignTokens.primary)
                                    .frame(width: 7, height: 7)
                                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                                Text(name)
                                    .font(.system(size: 14))
                                    .foregroundStyle(DesignTokens.textBody)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
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
                            Text(viewModel.contactName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(DesignTokens.textPrimary)
                            Text(viewModel.contactTypeBadge)
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(DesignTokens.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(DesignTokens.tagBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        Text(viewModel.contactDetails)
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.textBody)
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
            ScheduleViewingView(listingID: viewModel.listingID)
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
    NavigationStack {
        ListingDetailView(listing: HomeViewModel.previewListing)
    }
}
