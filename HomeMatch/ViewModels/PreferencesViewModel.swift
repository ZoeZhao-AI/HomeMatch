import Foundation
import Combine

@MainActor
final class PreferencesViewModel: ObservableObject {
    let currentPreference: HousingPreference
    let currentLifestyle: LifestyleProfile

    init(preference: HousingPreference, lifestyle: LifestyleProfile) {
        self.currentPreference = preference
        self.currentLifestyle = lifestyle
    }
}

// String keys matching the FilterChip option keys used in PreferencesView.
extension PreferencesViewModel {
    var roomTypeKey: String { Self.key(for: currentPreference.preferredRoomType) }
    var sleepKey: String { Self.key(for: currentLifestyle.sleepSchedule) }
    var noiseLevelKey: String { Self.key(for: currentLifestyle.noiseTolerance.dailyNoiseLevel) }
    var guestFrequencyKey: String { Self.key(for: currentLifestyle.noiseTolerance.guestFrequency) }
    var cookingKey: String { Self.key(for: currentLifestyle.cookingFrequency) }
    var cleanlinessKey: String { Self.key(for: currentLifestyle.cleanlinessLevel) }

    private static func key(for value: RoomType) -> String {
        switch value {
        case .privateRoom: return "privateRoom"
        case .sharedRoom: return "sharedRoom"
        case .entirePlace: return "entirePlace"
        }
    }

    private static func key(for value: SleepSchedule) -> String {
        switch value {
        case .veryEarly: return "veryEarly"
        case .early: return "early"
        case .moderate: return "moderate"
        case .late: return "late"
        case .veryLate: return "veryLate"
        case .flexible: return "flexible"
        }
    }

    private static func key(for value: DailyNoiseLevel) -> String {
        switch value {
        case .veryQuiet: return "veryQuiet"
        case .moderate: return "moderate"
        case .livelyOK: return "livelyOK"
        }
    }

    private static func key(for value: GuestFrequency) -> String {
        switch value {
        case .rarely: return "rarely"
        case .occasionally: return "occasionally"
        case .frequently: return "frequently"
        }
    }

    private static func key(for value: CookingFrequency) -> String {
        switch value {
        case .rarely: return "rarely"
        case .occasionally: return "occasionally"
        case .daily: return "daily"
        }
    }

    private static func key(for value: CleanlinessLevel) -> String {
        switch value {
        case .relaxed: return "relaxed"
        case .tidy: return "tidy"
        case .veryOrganised: return "veryOrganised"
        }
    }
}

// Temporary sample data — stand-in until a Repository is introduced.
extension PreferencesViewModel {
    static func mock() -> PreferencesViewModel {
        PreferencesViewModel(
            preference: HousingPreference(
                budgetRange: BudgetRange(min: 350, max: 500)!,
                preferredLocations: ["Ultimo", "Chippendale"],
                preferredRoomType: .privateRoom,
                requiresPetFriendly: false
            ),
            lifestyle: LifestyleProfile(
                userID: "current",
                sleepSchedule: .moderate,
                noiseTolerance: NoiseTolerance(dailyNoiseLevel: .moderate, guestFrequency: .occasionally),
                cookingFrequency: .occasionally,
                isSmoker: false,
                hasPets: false,
                cleanlinessLevel: .tidy
            )
        )
    }
}
