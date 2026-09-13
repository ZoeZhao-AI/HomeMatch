import SwiftUI

struct EditPreferencesView: View {
    private struct Draft: Equatable {
        var minBudget: String
        var maxBudget: String
        var locations: [String]
        var roomType: String?
        var petFriendlyOnly: Bool
        var sleep: String?
        var noise: String?
        var cooking: String?
        var cleanliness: String?
        var isSmoker: Bool
        var happyWithPets: Bool
    }

    // Temporary sample data — stand-in until wired to a ViewModel.
    private static let initialDraft = Draft(
        minBudget: "300",
        maxBudget: "420",
        locations: ["Ultimo", "Chippendale", "Redfern"],
        roomType: "privateRoom",
        petFriendlyOnly: false,
        sleep: "moderate",
        noise: "quiet",
        cooking: "fewTimesWeek",
        cleanliness: "tidy",
        isSmoker: false,
        happyWithPets: true
    )

    @Environment(\.dismiss) private var dismiss
    @State private var draft = EditPreferencesView.initialDraft

    // MARK: - Derived state

    private var budgetErrorMessage: String? {
        guard let min = Double(draft.minBudget),
              let max = Double(draft.maxBudget),
              max <= min else { return nil }
        return "Your maximum budget must be higher than your minimum. Try a maximum above $\(Int(min))."
    }

    private var isBudgetValid: Bool {
        guard let min = Double(draft.minBudget), let max = Double(draft.maxBudget) else { return false }
        return BudgetRange(min: min, max: max) != nil
    }

    private var canSave: Bool {
        draft != Self.initialDraft && isBudgetValid
    }

    private func save() {
        guard canSave else { return }
        // TODO: persist draft via a ViewModel / use case; pop only once that succeeds.
        dismiss()
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    userCard
                    housingSection
                    lifestyleSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }

            bottomBar
        }
        .background(DesignTokens.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Edit preferences")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack {
                Button("Cancel") {
                    // Draft is local @State, so popping discards any edits.
                    dismiss()
                }
                .font(.system(size: 16))
                .foregroundStyle(DesignTokens.primary)

                Spacer()

                Button("Save", action: save)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(canSave ? DesignTokens.primary : DesignTokens.disabledText)
                .disabled(!canSave)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DesignTokens.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)
        }
    }

    // MARK: - User card

    private var userCard: some View {
        HStack(spacing: 14) {
            InitialsAvatar(initials: "EC", size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("Emily Chen, 21")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("Bachelor of Communication · UTS")
                    .font(.system(size: 13.5))
                    .foregroundStyle(DesignTokens.textBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
        .cardShadow()
    }

    // MARK: - Housing preferences

    private var housingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("HOUSING PREFERENCES")

            card {
                budgetRow
                rowDivider
                locationRow
                rowDivider
                chipRow(title: "Room type", options: [
                    ("Private room", "privateRoom"),
                    ("Shared room", "sharedRoom"),
                    ("Entire place", "entirePlace")
                ], selected: $draft.roomType)
                rowDivider
                toggleRow(
                    title: "Pet-friendly homes only",
                    subtitle: "Show listings that allow pets",
                    isOn: $draft.petFriendlyOnly
                )
            }
        }
    }

    private var budgetRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                rowTitle("Weekly budget")
                Spacer()
                Text("AUD, incl. bills")
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            HStack(spacing: 12) {
                budgetInput(placeholder: "Min", text: $draft.minBudget)
                Text("–").foregroundStyle(DesignTokens.textTertiary)
                budgetInput(placeholder: "Max", text: $draft.maxBudget)
            }
            if let message = budgetErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.errorBorder)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func budgetInput(placeholder: String, text: Binding<String>) -> some View {
        let hasError = budgetErrorMessage != nil
        return HStack(spacing: 4) {
            Text("$").foregroundStyle(DesignTokens.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(hasError ? DesignTokens.errorBackground : DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hasError ? DesignTokens.errorBorder : DesignTokens.divider, lineWidth: 1)
        )
    }

    private var locationRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            rowTitle("Preferred location")
            FlowLayout(spacing: 8) {
                ForEach(draft.locations, id: \.self) { location in
                    RemovableChip(text: location) {
                        draft.locations.removeAll { $0 == location }
                    }
                }
                Button {
                    // TODO: add suburb
                } label: {
                    Text("+ Add suburb")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DesignTokens.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(
                            Capsule().stroke(DesignTokens.primary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Lifestyle preferences

    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("LIFESTYLE PREFERENCES")
                Text("Used to calculate your match percentages and to show honest differences.")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            card {
                chipRow(title: "Sleep schedule", options: [
                    ("Very early", "veryEarly"),
                    ("Early", "early"),
                    ("Moderate", "moderate"),
                    ("Late", "late"),
                    ("Very late", "veryLate"),
                    ("Flexible", "flexible")
                ], selected: $draft.sleep)
                rowDivider
                chipRow(title: "Noise tolerance", options: [
                    ("Quiet home", "quiet"),
                    ("Some noise ok", "someNoise"),
                    ("Lively", "lively")
                ], selected: $draft.noise)
                rowDivider
                chipRow(title: "Cooking frequency", options: [
                    ("Rarely", "rarely"),
                    ("2–3 times a week", "fewTimesWeek"),
                    ("Most nights", "mostNights")
                ], selected: $draft.cooking)
                rowDivider
                chipRow(title: "Cleanliness level", options: [
                    ("Relaxed", "relaxed"),
                    ("Tidy shared areas", "tidy"),
                    ("Spotless", "spotless")
                ], selected: $draft.cleanliness)
                rowDivider
                toggleRow(title: "I smoke", subtitle: "Includes vaping indoors", isOn: $draft.isSmoker)
                rowDivider
                toggleRow(
                    title: "I'm happy to live with pets",
                    subtitle: "Cats and dogs of housemates",
                    isOn: $draft.happyWithPets
                )
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        Button(action: save) {
            Text("Save")
                .font(.headline)
                .foregroundStyle(canSave ? Color.white : DesignTokens.disabledText)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.primaryButtonHeight)
                .background(canSave ? DesignTokens.primary : DesignTokens.disabledBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
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

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
        .cardShadow()
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(DesignTokens.divider.opacity(0.5))
            .frame(height: 1)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(DesignTokens.textSecondary)
    }

    private func rowTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(DesignTokens.textPrimary)
    }

    private func chipRow(title: String, options: [(String, String)], selected: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            rowTitle(title)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.1) { option in
                    FilterChip(text: option.0, isSelected: selected.wrappedValue == option.1) {
                        selected.wrappedValue = option.1
                    }
                }
            }
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                rowTitle(title)
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DesignTokens.primary)
        }
    }
}

#Preview {
    EditPreferencesView()
}
