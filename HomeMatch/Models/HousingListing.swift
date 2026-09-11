import Foundation

/// Represents a single rental property listing available on HomeMatch.
/// Business Rule: A listing must not be shown to the same user again within 7 days of being viewed.
struct HousingListing {
    let listingID: String
    let weeklyRent: Double
    let location: String
    let roomType: RoomType
    let isFurnished: Bool
    let isPetFriendly: Bool
    let facilities: [String]
    let minStayDuration: Int
    let photoURLs: [String]
    let contact: ListingContact
}

/// Represents the contact person responsible for a listing — either a landlord or a rental agent.
struct ListingContact {
    let contactName: String
    let contactType: ContactType
    let phoneNumber: String
    let email: String?
}

enum ContactType {
    case landlord
    case agent
}

enum RoomType {
    case privateRoom
    case sharedRoom
    case entirePlace
}
