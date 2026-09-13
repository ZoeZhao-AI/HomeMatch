import Foundation
import Combine

@MainActor
final class PreferencesViewModel: ObservableObject {
    enum SaveState {
        case idle
        case saved
        case error(UpdateHousingPreferenceError)
    }

    @Published private(set) var currentPreference: HousingPreference
    let currentLifestyle: LifestyleProfile
    @Published private(set) var saveState: SaveState = .idle

    private let updateUseCase: UpdateHousingPreferenceUseCase

    init(
        preference: HousingPreference,
        lifestyle: LifestyleProfile,
        updateUseCase: UpdateHousingPreferenceUseCase = UpdateHousingPreferenceUseCase()
    ) {
        self.currentPreference = preference
        self.currentLifestyle = lifestyle
        self.updateUseCase = updateUseCase
    }

    func save(
        budgetMinText: String,
        budgetMaxText: String,
        preferredLocations: [String],
        preferredRoomTypeKey: String?
    ) {
        guard let minValue = Double(budgetMinText),
              let maxValue = Double(budgetMaxText),
              let roomType = Self.roomType(fromKey: preferredRoomTypeKey) else {
            saveState = .error(.invalidBudgetRange)
            return
        }

        do {
            let outcome = try updateUseCase.execute(
                current: currentPreference,
                budgetMin: minValue,
                budgetMax: maxValue,
                preferredLocations: preferredLocations,
                preferredRoomType: roomType,
                requiresPetFriendly: currentPreference.requiresPetFriendly
            )
            switch outcome {
            case .updated(let newPref), .unchanged(let newPref):
                currentPreference = newPref
            }
            saveState = .saved
        } catch let error as UpdateHousingPreferenceError {
            saveState = .error(error)
        } catch {
            saveState = .error(.invalidBudgetRange)
        }
    }

    private static func roomType(fromKey key: String?) -> RoomType? {
        switch key {
        case "privateRoom": return .privateRoom
        case "sharedRoom": return .sharedRoom
        case "entirePlace": return .entirePlace
        default: return nil
        }
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
