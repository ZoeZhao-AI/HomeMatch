import Foundation

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
