import Foundation

/// Represents a candidate roommate's public profile, shown to other users
/// during roommate matching and contact.
/// Business Rule: users must be 18 years or older to have a profile on the platform.
///
/// Important consequence: every user — including the currently logged-in user (Emily) —
/// has their own `RoommateProfile`, since everyone is simultaneously a *viewer* (browsing
/// others) and a *candidate* (visible to others). `RoommateProfile` is not exclusively
/// "other people's profiles" — it is the one model representing a person on the platform.
///
/// This means UC1 (`MatchHousingListingsUseCase`) reads the current user's `HousingPreference`
/// via `currentUserRoommateProfile.housingPreference`, not from a separate standalone lookup.
/// The Repository layer should expose a way to fetch "the current user's own `RoommateProfile`"
/// distinctly from "candidate `RoommateProfile`s to match against."
struct RoommateProfile {
    let userID: String
    let displayName: String
    let age: Int
    let occupation: String
    let profilePhotoURL: String?
    let lifestyleProfile: LifestyleProfile
    let housingPreference: HousingPreference   // composed per instructor feedback — see 2.2
    let shortBio: String?

    init?(userID: String, displayName: String, age: Int, occupation: String,
          profilePhotoURL: String?, lifestyleProfile: LifestyleProfile,
          housingPreference: HousingPreference, shortBio: String?) {
        guard age >= 18 else { return nil }
        self.userID = userID
        self.displayName = displayName
        self.age = age
        self.occupation = occupation
        self.profilePhotoURL = profilePhotoURL
        self.lifestyleProfile = lifestyleProfile
        self.housingPreference = housingPreference
        self.shortBio = shortBio
    }
}
