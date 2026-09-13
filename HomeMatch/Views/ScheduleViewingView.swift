import SwiftUI

struct ScheduleViewingView: View {
    private struct TimeSlot: Identifiable {
        let time: String
        let detail: String
        let isFullyBooked: Bool
        var id: String { time }
    }

    // Weeks start on Monday (Australian convention).
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }()
    private static let locale = Locale(identifier: "en_AU")
    private let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]

    @State private var displayedMonth: Date = ScheduleViewingView.calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
    @State private var selectedDate: Date = ScheduleViewingView.calendar.date(from: DateComponents(year: 2026, month: 9, day: 9))!

    // Temporary sample data — stand-in until wired to ScheduleViewingUseCase.
    // Only September 2026 has mockup availability; every other month uses placeholder slots.
    private let september2026InspectionDays: Set<Int> = [9, 11, 12, 16, 19, 23, 26]

    private let september2026Slots: [TimeSlot] = [
        TimeSlot(time: "10:00 – 10:20 am", detail: "Open inspection · 3 others going", isFullyBooked: false),
        TimeSlot(time: "12:30 – 12:50 pm", detail: "Private viewing with agent", isFullyBooked: false),
        TimeSlot(time: "4:15 – 4:35 pm", detail: "Private viewing with agent", isFullyBooked: false),
        TimeSlot(time: "5:30 – 5:50 pm", detail: "Fully booked", isFullyBooked: true)
    ]

    private let placeholderSlots: [TimeSlot] = [
        TimeSlot(time: "9:00 – 9:20 am", detail: "Private viewing with agent", isFullyBooked: false),
        TimeSlot(time: "1:00 – 1:20 pm", detail: "Open inspection", isFullyBooked: false),
        TimeSlot(time: "3:30 – 3:50 pm", detail: "Private viewing with agent", isFullyBooked: false)
    ]

    private let selectedSlotTime = "12:30 – 12:50 pm"

    private var slots: [TimeSlot] {
        isSeptember2026(selectedDate) ? september2026Slots : placeholderSlots
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    calendarCard
                    availableTimesSection
                    pendingRequestsCallout
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }

            bottomBar
        }
        .background(DesignTokens.pageBackground)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Request a viewing")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DesignTokens.textPrimary)

            HStack {
                Button {
                    // TODO: navigate back to ListingDetailView
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Listing")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(DesignTokens.primary)
                }
                .buttonStyle(.plain)
                Spacer()
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

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(monthTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DesignTokens.textPrimary)
                Spacer()
                monthArrow(systemName: "chevron.left", label: "Previous month", offset: -1)
                monthArrow(systemName: "chevron.right", label: "Next month", offset: 1)
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .frame(height: 20)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                // Negative ids so blank cells can't collide with day numbers.
                ForEach(-leadingBlankDays..<0, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    dayCell(day)
                }
            }

            Rectangle()
                .fill(DesignTokens.divider.opacity(0.5))
                .frame(height: 1)

            HStack(spacing: 16) {
                legendItem(color: DesignTokens.primary, text: "Selected")
                legendItem(color: DesignTokens.textTertiary, text: "Inspection times available")
            }
        }
        .padding(16)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
        .cardShadow()
    }

    private func monthArrow(systemName: String, label: String, offset: Int) -> some View {
        Button {
            if let month = Self.calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
                displayedMonth = month
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignTokens.primary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func dayCell(_ day: Int) -> some View {
        let date = dateInDisplayedMonth(day: day)
        let isSelected = Self.calendar.isDate(date, inSameDayAs: selectedDate)
        let hasInspections = isSeptember2026(displayedMonth) && september2026InspectionDays.contains(day)
        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.white : DesignTokens.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(isSelected ? DesignTokens.primary : Color.clear))
                Circle()
                    .fill(hasInspections && !isSelected ? DesignTokens.textTertiary : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date helpers

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year().locale(Self.locale))
    }

    /// Blank cells before day 1 so it lands under the right weekday (Monday-first).
    private var leadingBlankDays: Int {
        let weekday = Self.calendar.component(.weekday, from: displayedMonth)
        return (weekday - Self.calendar.firstWeekday + 7) % 7
    }

    private var daysInMonth: Int {
        Self.calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private func dateInDisplayedMonth(day: Int) -> Date {
        var components = Self.calendar.dateComponents([.year, .month], from: displayedMonth)
        components.day = day
        return Self.calendar.date(from: components) ?? displayedMonth
    }

    private func isSeptember2026(_ date: Date) -> Bool {
        let components = Self.calendar.dateComponents([.year, .month], from: date)
        return components.year == 2026 && components.month == 9
    }

    /// e.g. "Wed 9 Sept"; the year is appended when it isn't the current year.
    private var selectedDateLabel: String {
        let dayLabel = selectedDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Self.locale))
        let isCurrentYear = Self.calendar.isDate(selectedDate, equalTo: Date(), toGranularity: .year)
        return isCurrentYear ? dayLabel : "\(dayLabel) \(Self.calendar.component(.year, from: selectedDate))"
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(DesignTokens.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Available times

    private var availableTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available times — \(selectedDateLabel)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(slots) { slot in
                slotCard(slot)
            }
        }
    }

    private func slotCard(_ slot: TimeSlot) -> some View {
        let isSelected = slot.time == selectedSlotTime
        return VStack(alignment: .leading, spacing: 4) {
            Text(slot.time)
                .font(.system(size: 16, weight: .semibold))
                .strikethrough(slot.isFullyBooked)
                .foregroundStyle(slot.isFullyBooked ? DesignTokens.disabledText : DesignTokens.textPrimary)
            Text(slot.detail)
                .font(.system(size: 13))
                .foregroundStyle(slot.isFullyBooked ? DesignTokens.disabledText : DesignTokens.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(slot.isFullyBooked ? DesignTokens.disabledBackground : DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected ? DesignTokens.primary : DesignTokens.divider.opacity(0.6),
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }

    // MARK: - Pending requests callout

    private var pendingRequestsCallout: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DesignTokens.primary)
            Text("You can hold up to 3 pending viewing requests at a time. You currently have 1 pending.")
                .font(.system(size: 13.5))
                .foregroundStyle(DesignTokens.textBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.tagBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        Button {
            // TODO: submit viewing request
        } label: {
            Text("Request viewing")
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
}

#Preview {
    ScheduleViewingView()
}
