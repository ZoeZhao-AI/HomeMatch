import Foundation
import Combine

@MainActor
final class ListingDetailViewModel: ObservableObject {
    struct DetailRow: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    let listing: HousingListing

    init(listing: HousingListing) {
        self.listing = listing
    }

    var listingID: String { listing.listingID }

    var rentLabel: String { "$\(Int(listing.weeklyRent.rounded()))" }

    var address: String { listing.location }

    var roomTypeLabel: String {
        switch listing.roomType {
        case .privateRoom: return "Private room"
        case .sharedRoom: return "Shared room"
        case .entirePlace: return "Entire place"
        }
    }

    var tags: [String] {
        [roomTypeLabel]
            + (listing.isFurnished ? ["Furnished"] : [])
            + (listing.isPetFriendly ? ["Pet-friendly"] : [])
    }

    var detailRows: [DetailRow] {
        [
            DetailRow(label: "Room type", value: roomTypeLabel),
            DetailRow(label: "Furnished", value: listing.isFurnished ? "Yes" : "No"),
            DetailRow(label: "Pet-friendly", value: listing.isPetFriendly ? "Yes" : "No"),
            DetailRow(
                label: "Minimum stay",
                value: listing.minStayDuration == 1 ? "1 month" : "\(listing.minStayDuration) months"
            )
        ]
    }

    var facilityNames: [String] {
        listing.facilities.map(Self.facilityName(for:))
    }

    var contactName: String { listing.contact.contactName }

    var contactTypeBadge: String {
        switch listing.contact.contactType {
        case .agent: return "AGENT"
        case .landlord: return "LANDLORD"
        }
    }

    /// Phone (formatted as "0400 000 000" when it's a 10-digit mobile) and email, when present.
    var contactDetails: String {
        let phone = listing.contact.phoneNumber
        let formattedPhone: String
        if phone.count == 10, phone.allSatisfy(\.isNumber) {
            let digits = Array(phone)
            formattedPhone = "\(String(digits[0..<4])) \(String(digits[4..<7])) \(String(digits[7..<10]))"
        } else {
            formattedPhone = phone
        }
        return [formattedPhone, listing.contact.email].compactMap { $0 }.joined(separator: " · ")
    }

    private static func facilityName(for key: String) -> String {
        switch key.lowercased() {
        case "wifi": return "WiFi"
        case "laundry": return "Laundry"
        case "aircon": return "Air conditioning"
        case "parking": return "Parking"
        case "dishwasher": return "Dishwasher"
        default: return key.prefix(1).uppercased() + key.dropFirst()
        }
    }
}
