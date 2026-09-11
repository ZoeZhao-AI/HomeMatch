import Foundation

struct LifestyleProfile {
    let userID: String
    let sleepSchedule: SleepSchedule
    let noiseTolerance: NoiseTolerance
    let cookingFrequency: CookingFrequency
    let isSmoker: Bool
    let hasPets: Bool
    let cleanlinessLevel: CleanlinessLevel
}

enum SleepSchedule {
    case veryEarly
    case early
    case moderate
    case late
    case veryLate
    case flexible
}

struct NoiseTolerance {
    let dailyNoiseLevel: DailyNoiseLevel
    let guestFrequency: GuestFrequency
}

enum DailyNoiseLevel {
    case veryQuiet
    case moderate
    case livelyOK
}

enum GuestFrequency {
    case rarely
    case occasionally
    case frequently
}

enum CookingFrequency {
    case rarely
    case occasionally
    case daily
}

enum CleanlinessLevel {
    case relaxed
    case tidy
    case veryOrganised
}
