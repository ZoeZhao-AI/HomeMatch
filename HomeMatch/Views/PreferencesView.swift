import SwiftUI

struct PreferencesView: View {
    enum Tab { case findHome, findRoommate }

    @StateObject private var viewModel: PreferencesViewModel

    @State private var selectedTab: Tab = .findHome

    // Find a Home
    @State private var homeDescription = ""
    @State private var minBudget: String
    @State private var maxBudget: String
    @State private var locations: [String]
    @State private var selectedRoomType: String?
    @State private var maxCommuteMinutes: Double = 20
    @State private var moveInDate: Date = Date()

    // Find a Roommate
    @State private var roommateDescription = ""
    @State private var selectedSleep: String?
    @State private var selectedNoise: String?
    @State private var selectedGuest: String?
    @State private var selectedCooking: String?
    @State private var selectedCleanliness: String?
    @State private var isSmoker: Bool
    @State private var hasPets: Bool

    @MainActor
    init(viewModel: PreferencesViewModel? = nil) {
        let vm = viewModel ?? .mock()
        _viewModel = StateObject(wrappedValue: vm)
        _minBudget = State(initialValue: String(Int(vm.currentPreference.budgetRange.min)))
        _maxBudget = State(initialValue: String(Int(vm.currentPreference.budgetRange.max)))
        _locations = State(initialValue: vm.currentPreference.preferredLocations)
        _selectedRoomType = State(initialValue: vm.roomTypeKey)
        _selectedSleep = State(initialValue: vm.sleepKey)
        _selectedNoise = State(initialValue: vm.noiseLevelKey)
        _selectedGuest = State(initialValue: vm.guestFrequencyKey)
        _selectedCooking = State(initialValue: vm.cookingKey)
        _selectedCleanliness = State(initialValue: vm.cleanlinessKey)
        _isSmoker = State(initialValue: vm.currentLifestyle.isSmoker)
        _hasPets = State(initialValue: vm.currentLifestyle.hasPets)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("AI Match")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(DesignTokens.textPrimary)

                tabSwitcher

                if selectedTab == .findHome {
                    findHomeSection
                } else {
                    findRoommateSection
                }
            }
            .padding(20)
        }
        .background(DesignTokens.pageBackground)
    }

    // MARK: - Tab switcher

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            tabButton("Find a Home", tab: .findHome)
            tabButton("Find a Roommate", tab: .findRoommate)
        }
        .padding(4)
        .background(DesignTokens.tagBackground)
        .clipShape(Capsule())
    }

    private func tabButton(_ label: String, tab: Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selectedTab == tab ? Color.white : DesignTokens.textBody)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedTab == tab ? DesignTokens.primary : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Find a Home

    private var findHomeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            descriptionField(text: $homeDescription, placeholder: "Tell us what you're looking for…")
            budgetSection
            locationSection
            roomTypeSection
            commuteSection
            moveInDateSection
            saveSection
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Weekly budget")
            HStack(spacing: 12) {
                budgetInput(placeholder: "Min", text: $minBudget)
                Text("–").foregroundStyle(DesignTokens.textTertiary)
                budgetInput(placeholder: "Max", text: $maxBudget)
            }
            if case .error(let error) = viewModel.saveState, let message = error.errorDescription {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.errorBorder)
            }
        }
    }

    private var hasBudgetError: Bool {
        if case .error = viewModel.saveState { return true }
        return false
    }

    private func budgetInput(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Text("$").foregroundStyle(DesignTokens.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(hasBudgetError ? DesignTokens.errorBackground : DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hasBudgetError ? DesignTokens.errorBorder : DesignTokens.divider, lineWidth: 1)
        )
    }

    private var saveSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.save(
                    budgetMinText: minBudget,
                    budgetMaxText: maxBudget,
                    preferredLocations: locations,
                    preferredRoomTypeKey: selectedRoomType
                )
            } label: {
                Text("Save preferences")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.primaryButtonHeight)
                    .background(DesignTokens.primary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius))
            }
            .buttonStyle(.plain)

            if case .saved = viewModel.saveState {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Preferences saved")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DesignTokens.primary)
            }
        }
        .padding(.top, 8)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Preferred locations")
            FlowLayout(spacing: 8) {
                ForEach(locations, id: \.self) { loc in
                    RemovableChip(text: loc) {
                        locations.removeAll { $0 == loc }
                    }
                }
            }
        }
    }

    private var roomTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Room type")
            FlowLayout(spacing: 8) {
                FilterChip(text: "Private room", isSelected: selectedRoomType == "privateRoom") {
                    selectedRoomType = "privateRoom"
                }
                FilterChip(text: "Shared room", isSelected: selectedRoomType == "sharedRoom") {
                    selectedRoomType = "sharedRoom"
                }
                FilterChip(text: "Entire place", isSelected: selectedRoomType == "entirePlace") {
                    selectedRoomType = "entirePlace"
                }
            }
        }
    }

    private var commuteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader("Max commute")
                Spacer()
                Text("\(Int(maxCommuteMinutes)) min")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DesignTokens.primary)
            }
            Slider(value: $maxCommuteMinutes, in: 5...60, step: 5)
                .tint(DesignTokens.primary)
        }
    }

    private var moveInDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Move-in date")
            DatePicker("", selection: $moveInDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(DesignTokens.primary)
        }
    }

    // MARK: - Find a Roommate

    private var findRoommateSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            descriptionField(text: $roommateDescription, placeholder: "Tell us about you and what you're looking for…")

            chipGroup(header: "Sleep schedule", options: [
                ("Very early", "veryEarly"),
                ("Early", "early"),
                ("Moderate", "moderate"),
                ("Late", "late"),
                ("Very late", "veryLate"),
                ("Flexible", "flexible")
            ], selected: $selectedSleep)

            chipGroup(header: "Daily noise tolerance", options: [
                ("Very quiet", "veryQuiet"),
                ("Moderate", "moderate"),
                ("Lively OK", "livelyOK")
            ], selected: $selectedNoise)

            chipGroup(header: "Guest frequency", options: [
                ("Rarely", "rarely"),
                ("Occasionally", "occasionally"),
                ("Frequently", "frequently")
            ], selected: $selectedGuest)

            chipGroup(header: "Cooking frequency", options: [
                ("Rarely", "rarely"),
                ("Occasionally", "occasionally"),
                ("Daily", "daily")
            ], selected: $selectedCooking)

            chipGroup(header: "Cleanliness", options: [
                ("Relaxed", "relaxed"),
                ("Tidy", "tidy"),
                ("Very organised", "veryOrganised")
            ], selected: $selectedCleanliness)

            togglesSection
        }
    }

    private var togglesSection: some View {
        VStack(spacing: 12) {
            toggleRow("I smoke", isOn: $isSmoker)
            Divider().background(DesignTokens.divider)
            toggleRow("I have pets", isOn: $hasPets)
        }
        .padding(16)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
        .cardShadow()
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textBody)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DesignTokens.primary)
        }
    }

    // MARK: - Shared helpers

    private func chipGroup(
        header: String,
        options: [(String, String)],
        selected: Binding<String?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(header)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.1) { option in
                    FilterChip(text: option.0, isSelected: selected.wrappedValue == option.1) {
                        selected.wrappedValue = option.1
                    }
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DesignTokens.textPrimary)
    }

    private func descriptionField(text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("About")
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(DesignTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignTokens.divider, lineWidth: 1)
                )
        }
    }
}

// MARK: - Chip components + flow layout (inline; only used by this screen)

private struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : DesignTokens.textBody)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? DesignTokens.primary : DesignTokens.tagBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct RemovableChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(DesignTokens.textBody)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DesignTokens.tagBackground)
        .clipShape(Capsule())
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(subviews: subviews, maxWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, maxWidth: bounds.width)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            contentWidth = max(contentWidth, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return (positions, CGSize(width: contentWidth, height: y + rowHeight))
    }
}

#Preview {
    PreferencesView()
}
