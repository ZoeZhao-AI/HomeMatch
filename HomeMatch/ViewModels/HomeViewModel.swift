import Foundation
import Combine

struct ScoredListing: Identifiable {
    let listing: HousingListing
    let score: ListingMatchScore
    var id: String { listing.listingID }
}

@MainActor
final class HomeViewModel: ObservableObject {
    enum State {
        case loading
        case loaded(recommended: [ScoredListing], all: [ScoredListing])
        case noListingsAvailable
    }

    @Published private(set) var state: State = .loading

    private let useCase: MatchHousingListingsUseCase
    private let preference: HousingPreference
    private let listings: [HousingListing]

    init(
        preference: HousingPreference,
        listings: [HousingListing],
        useCase: MatchHousingListingsUseCase = MatchHousingListingsUseCase()
    ) {
        self.preference = preference
        self.listings = listings
        self.useCase = useCase
    }

    func load() {
        state = .loading
        do {
            let result = try useCase.execute(listings: listings, preference: preference)
            let recommended = result.recommended.map { ScoredListing(listing: $0.listing, score: $0.score) }
            let all = result.all.map { ScoredListing(listing: $0.listing, score: $0.score) }
            state = .loaded(recommended: recommended, all: all)
        } catch {
            state = .noListingsAvailable
        }
    }
}

// Temporary sample data — stand-in until a Repository is introduced.
extension HomeViewModel {
    static func mock() -> HomeViewModel {
        HomeViewModel(preference: sampleUserPreference, listings: sampleListings)
    }

    private static let sampleUserPreference = HousingPreference(
        budgetRange: BudgetRange(min: 350, max: 500)!,
        preferredLocations: ["Ultimo", "Chippendale"],
        preferredRoomType: .privateRoom,
        requiresPetFriendly: false
    )

    /// 42 Turner St (L3), for previews of listing screens.
    static var previewListing: HousingListing { sampleListings[2] }

    private static let sampleListings: [HousingListing] = [
        HousingListing(
            listingID: "L1",
            weeklyRent: 450,
            location: "42 Broadway St, Ultimo NSW 2007",
            roomType: .privateRoom,
            isFurnished: true,
            isPetFriendly: true,
            facilities: ["wifi", "laundry", "aircon"],
            minStayDuration: 6,
            photoURLs: [],
            contact: ListingContact(contactName: "Alex", contactType: .agent, phoneNumber: "0400000000", email: nil)
        ),
        HousingListing(
            listingID: "L2",
            weeklyRent: 400,
            location: "18 Regent St, Chippendale NSW 2008",
            roomType: .privateRoom,
            isFurnished: true,
            isPetFriendly: false,
            facilities: ["wifi", "laundry"],
            minStayDuration: 6,
            photoURLs: [],
            contact: ListingContact(contactName: "Jamie", contactType: .landlord, phoneNumber: "0400000001", email: nil)
        ),
        HousingListing(
            listingID: "L3",
            weeklyRent: 380,
            location: "42 Turner St, Redfern NSW 2016",
            roomType: .privateRoom,
            isFurnished: false,
            isPetFriendly: false,
            facilities: ["wifi"],
            minStayDuration: 12,
            photoURLs: [],
            contact: ListingContact(contactName: "Sam", contactType: .agent, phoneNumber: "0400000002", email: nil)
        ),
        HousingListing(
            listingID: "L4",
            weeklyRent: 700,
            location: "10 Harris St, Ultimo NSW 2007",
            roomType: .privateRoom,
            isFurnished: false,
            isPetFriendly: false,
            facilities: ["wifi"],
            minStayDuration: 6,
            photoURLs: [],
            contact: ListingContact(contactName: "Riley", contactType: .agent, phoneNumber: "0400000003", email: nil)
        )
    ]
}
