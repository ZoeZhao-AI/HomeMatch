import SwiftUI

struct ProfileView: View {
    private let accountRows = ["Notifications", "Privacy & safety", "Help & support"]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileCard
                    housingAndLifestyleSection
                    accountSection
                    signOutCard

                    Text("HomeMatch 1.4.2 · Sydney")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.textTertiary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(DesignTokens.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        Text("Profile")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(DesignTokens.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(DesignTokens.cardBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(DesignTokens.divider.opacity(0.5))
                    .frame(height: 1)
            }
    }

    // MARK: - Profile card

    private var profileCard: some View {
        HStack(alignment: .top, spacing: 14) {
            InitialsAvatar(initials: "EC", size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text("Emily Chen, 21")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("Bachelor of Communication · UTS")
                    .font(.system(size: 13.5))
                    .foregroundStyle(DesignTokens.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                VerifiedBadge()
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
        .cardShadow()
    }

    // MARK: - Housing & lifestyle

    private var housingAndLifestyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("HOUSING & LIFESTYLE")

            NavigationLink {
                EditPreferencesView()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Edit preferences")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text("Budget, suburbs, room type and lifestyle answers")
                            .font(.system(size: 12.5))
                            .foregroundStyle(DesignTokens.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    chevron
                }
                .padding(16)
                .background(DesignTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
                .cardShadow()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ACCOUNT")

            VStack(spacing: 0) {
                ForEach(Array(accountRows.enumerated()), id: \.offset) { index, title in
                    if index > 0 {
                        Rectangle()
                            .fill(DesignTokens.divider.opacity(0.5))
                            .frame(height: 1)
                    }
                    HStack {
                        Text(title)
                            .font(.system(size: 15))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Spacer()
                        chevron
                    }
                    .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 16)
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
            .cardShadow()
        }
    }

    // MARK: - Sign out

    private var signOutCard: some View {
        Text("Sign out")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(DesignTokens.errorBorder)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
            .cardShadow()
    }

    // MARK: - Helpers

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(DesignTokens.textTertiary)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(DesignTokens.textSecondary)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
