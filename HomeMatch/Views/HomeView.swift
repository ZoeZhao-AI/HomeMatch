import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Binding private var selectedTab: AppTab
    @State private var showAll = false

    @MainActor
    init(selectedTab: Binding<AppTab>, viewModel: HomeViewModel? = nil) {
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: viewModel ?? .mock())
    }

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
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.load()
        }
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
            selectedTab = .aiMatch
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
                Text(showAll ? "All homes" : "Recommended homes")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Spacer()
                if case .loaded(let recommended, let all) = viewModel.state, all.count > recommended.count {
                    Button(showAll ? "Recommended only" : "Show all (\(all.count))") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAll.toggle()
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DesignTokens.primary)
                }
            }

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .tint(DesignTokens.primary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            case .noListingsAvailable:
                emptyState(message: "No listings are available right now. Please check back soon.")
            case .loaded(let recommended, let all):
                // Business rule: below-60% listings stay hidden until the user opts into "Show all".
                let visible = showAll ? all : recommended

                if visible.isEmpty {
                    emptyState(message: "No strong matches yet. Tap Show all to see every listing.")
                } else {
                    ForEach(visible) { scored in
                        NavigationLink {
                            ListingDetailView(listing: scored.listing)
                        } label: {
                            ListingCardView(data: ListingCardData(scored: scored))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "house.slash")
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
}

#Preview {
    HomeView(selectedTab: .constant(.home))
}
