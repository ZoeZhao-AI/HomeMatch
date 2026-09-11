# HomeMatch — Development Specification

**App**: HomeMatch — an AI-powered housing and roommate matching platform
**Primary stakeholder**: Emily Chen, 21, university student, Sydney (UTS)
**Domain**: Property / housing services, roommate matching

This document is the single source of truth for development. It consolidates
all design decisions made during the planning phase: Use Cases, Domain Models,
Protocols, and UI design tokens. Claude Code should treat this file as the
authoritative spec — implementation should follow it exactly, and any
ambiguity should be flagged rather than guessed.

---

## 1. Use Cases (5)

### UC1 — MatchHousingListingsUseCase

**Actor**: Emily
**Description**: When the user opens the home screen, the system uses the
user's saved housing preferences (budget, location, room type, etc.) to
calculate and display a ranked list of recommended housing listings.

**Preconditions**: User is logged in; the system has already recorded the
user's saved housing preferences.

**Main Flow**:
1. User opens the home screen
2. System reads the user's saved `HousingPreference`
3. System calculates a `ListingMatchScore` between each `HousingListing` and
   the user's preferences
4. System displays listings ranked by match score, with match percentage shown

**Business Rules**:
- Listings scoring below 60% match are not actively recommended, but the user
  can choose "Show all"
- The same listing is not shown to the same user again within 7 days, to
  avoid repeated exposure to the same result

**Failure Scenarios**:
- Preferences too narrow → no listings meet the 60% threshold → the UI shows
  "No listings match your current criteria. Try widening your budget or
  considering nearby areas?" with a one-tap option to relax filters, AND a
  "Show all" option that reveals the lower-scoring results
- No listings available at all (e.g. empty catalogue) → throws
  `MatchHousingListingsError.noListingsAvailable`
- No preferences set yet → "Please complete your AI Match preferences first
  to get personalised listings," redirect to preference setup screen

> **Design note (discovered during unit testing)**: the original spec implied
> "zero matches" should throw an error. In practice, this only makes sense
> when there is literally no data to work with (`noListingsAvailable`, when
> the input listings array is empty). When there IS data but none of it
> clears the 60% recommendation threshold, throwing an error would break the
> "Show all" business rule — the UI still needs access to the low-scoring
> results to let the user reveal them. So `execute()` returns a structured
> result distinguishing "recommended" from "all", rather than throwing when
> scores are merely low:
>
> ```swift
> struct MatchHousingListingsResult {
>     let recommended: [(listing: HousingListing, score: ListingMatchScore)]
>     let all: [(listing: HousingListing, score: ListingMatchScore)]
> }
> ```
>
> `MatchHousingListingsError.noMatchesFound` is removed — it conflated two
> different situations (no data vs. low-quality data) that need different UI
> treatment.

---

### UC2 — ScheduleViewingUseCase

**Actor**: Emily
**Description**: From a listing's detail page, the user selects an available
time slot and submits a request to schedule an in-person viewing.

**Preconditions**: User is logged in and viewing a specific listing's detail
page.

**Main Flow**:
1. User taps "Schedule viewing"
2. User selects an available time slot
3. System validates that the time slot is available
4. System submits the `ViewingRequest` with status `.pending`
5. System confirms submission to the user

**Business Rules**:
- A user cannot submit more than one viewing request for the same listing
  within a 24-hour window (enforced in Use Case layer — requires querying
  multiple `ViewingRequest` instances)
- The selected time slot must be in the future (enforced in `ViewingRequest`
  initializer)
- A user may hold at most 3 `.pending` viewing requests at any given time
  (enforced in Use Case layer)

**Failure Scenarios**:
- Past time slot selected → "Please choose a future time slot to schedule
  your viewing"
- Duplicate request within 24h → "You've already requested a viewing for
  this listing. Please wait for confirmation or try again after 24 hours"
- Already has 3 pending requests → "You already have 3 pending viewings.
  Please complete or cancel one before scheduling another"

---

### UC3 — MatchRoommatesUseCase (PRIMARY USE CASE)

**Actor**: Emily
**Description**: After the user fills in their lifestyle preferences, the
system calculates compatibility scores against candidate roommates and
displays a ranked list; the user can then view a candidate's full match
details.

**Preconditions**: User is logged in and has completed their `LifestyleProfile`.

**Main Flow**:
1. User enters the AI Match screen (Roommate tab)
2. User fills in / confirms `LifestyleProfile`
3. System calculates a `CompatibilityScore` for each candidate `RoommateProfile`
4. System displays candidates ranked by compatibility score
5. User taps a candidate to view detailed profile (including "Why you match"
   and "Potential differences")

**Business Rules**:
- Candidates scoring below 60% compatibility are not actively recommended
  (`isRecommended` computed property)
- Lifestyle conflict points must be explicitly shown in Match Details and
  cannot be hidden or simplified away (`conflictPoints` field, always
  rendered in UI)

**Failure Scenarios**:
- Incomplete lifestyle info → "Please complete your lifestyle information
  for more accurate matching," highlight missing fields
- No candidates meet 60% threshold → "No highly compatible roommates found
  right now. Would you like to see lower-compatibility candidates instead?"
  with "Show all" option

---

### UC4 — InitiateRoommateContactUseCase

**Actor**: Emily
**Description**: From a candidate roommate's Match Details page, the user
taps the DM icon to open a conversation thread, and may share a previously
viewed listing within that conversation.

**Preconditions**: User is logged in and viewing a specific candidate's
Match Details page.

**Main Flow**:
1. User taps the DM icon on a candidate's profile
2. System creates or opens a conversation thread with that candidate
3. User sends a `Message`
4. User may optionally share a `HousingListing` they have previously viewed
   or saved

**Business Rules**:
- A user cannot send more than 5 messages to the same candidate within a
  1-minute window (anti-spam)
- A shared listing must be one the user has already viewed or saved

**Failure Scenarios**:
- Sending too rapidly → "You're sending messages too quickly. Please wait
  a moment," temporarily disable send button
- Attempting to share an unviewed listing (defensive check) → "Please view
  this listing first before sharing it"

---

### UC5 — UpdateHousingPreferenceUseCase

**Actor**: Emily
**Description**: The user modifies their existing `HousingPreference` on the
profile/settings screen; saving triggers the home screen to re-run matching.

**Preconditions**: User already has an existing saved `HousingPreference`.

**Main Flow**:
1. User enters the profile/preferences screen
2. User re-selects filters and modifies preferences
3. User taps "Save"
4. System validates the new preference values (`BudgetRange` init)
5. System updates the saved record; home screen re-triggers matching

**Business Rules**:
- `BudgetRange.max` must be greater than `min`, and both must be positive
  (enforced in `BudgetRange` initializer)
- If new preferences are identical to existing ones, re-matching is not
  re-triggered (avoids unnecessary recomputation)

**Failure Scenarios**:
- Budget max < min → "Your maximum budget must be higher than your minimum.
  Please check and re-enter," highlight affected fields (this is the live
  validation state shown in the Hi-Fi mockup, Screen 8)
- Required field cleared before saving → "[Field name] cannot be empty.
  Please fill it in before saving," block save action

---

## 2. Domain Models (8)

### 2.1 HousingListing

```swift
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
```

### 2.2 HousingPreference

> ✅ **RESOLVED per instructor feedback (Shuvam).**
> The instructor confirmed that `HousingPreference` should not be a
> free-floating model connected only by `userID`. Instead, it is composed
> *inside* `RoommateProfile` — the same pattern already used for
> `LifestyleProfile`. This gives `HousingPreference` an explicit structural
> connection (composition) rather than an implicit one. See the updated
> `RoommateProfile` definition in section 2.6.

```swift
/// Represents a valid weekly rent budget range.
/// Business Rule: max must be greater than min, and both must be positive values.
struct BudgetRange {
    let min: Double
    let max: Double

    init?(min: Double, max: Double) {
        guard max > min, min > 0 else { return nil }
        self.min = min
        self.max = max
    }
}

/// Represents a user's housing search criteria — budget, location, and property requirements.
/// Composed inside RoommateProfile (see section 2.6) rather than existing as a
/// free-floating model — this gives it an explicit structural connection.
struct HousingPreference {
    let budgetRange: BudgetRange
    let preferredLocations: [String]   // supports multiple candidate areas — see fix note below
    let preferredRoomType: RoomType
    let requiresPetFriendly: Bool
}
```

> **Fix note (during UC1 implementation)**: `preferredLocation` was originally
> a single `String`, but the Hi-Fi mockup (Screen 2) shows users selecting
> multiple location chips (e.g. Ultimo, Chippendale, Redfern simultaneously).
> Changed to `preferredLocations: [String]` so a listing matches if its
> location contains any one of the preferred areas (substring match, not
> exact equality).

> Note: `userID` has been removed from this struct — since `HousingPreference`
> now lives inside `RoommateProfile`, which already carries `userID`, keeping
> it here would be redundant.

### 2.3 LifestyleProfile

```swift
/// Represents a user's day-to-day lifestyle habits, used to calculate
/// roommate compatibility in CompatibilityScore.
struct LifestyleProfile {
    let userID: String
    let sleepSchedule: SleepSchedule
    let noiseTolerance: NoiseTolerance
    let cookingFrequency: CookingFrequency
    let isSmoker: Bool
    let hasPets: Bool
    let cleanlinessLevel: CleanlinessLevel
}

/// Represents when a user typically goes to sleep.
/// Business Rule: used to calculate sleep schedule alignment in CompatibilityScore.
enum SleepSchedule {
    case veryEarly    // before 9pm
    case early        // 9pm–11pm
    case moderate      // 11pm–1am
    case late          // 1am–3am
    case veryLate      // after 3am
    case flexible      // varies day to day
}

/// Represents a user's tolerance for noise in shared living spaces.
/// Business Rule: used to calculate noise-related conflict points in CompatibilityScore's "Potential Differences".
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
```

### 2.4 ListingMatchScore

```swift
/// Represents how well a specific housing listing matches a user's housing preferences.
/// Business Rule: listings scoring below 60% are not actively recommended,
/// but remain visible if the user chooses "Show all".
struct ListingMatchScore: RecommendationScoring {
    let listingID: String
    let budgetMatchScore: Double          // weight 35%
    let locationMatchScore: Double        // weight 30%
    let roomTypeMatchScore: Double        // weight 20%
    let facilitiesMatchScore: Double      // weight 15%

    var overallScore: Double {
        (budgetMatchScore * 0.35)
        + (locationMatchScore * 0.30)
        + (roomTypeMatchScore * 0.20)
        + (facilitiesMatchScore * 0.15)
    }

    var isRecommended: Bool {
        overallScore >= 60.0
    }
}
```

### 2.5 CompatibilityScore

```swift
/// Represents the compatibility between the current user and a candidate roommate,
/// based on their respective LifestyleProfiles.
/// Business Rule: candidates scoring below 60% overall are not actively recommended,
/// but remain visible if the user chooses "Show all".
/// Business Rule: any lifestyle conflict points must be explicitly surfaced, not hidden.
struct CompatibilityScore: RecommendationScoring {
    let candidateID: String
    let sleepScheduleMatchScore: Double      // weight 25%
    let noiseToleranceMatchScore: Double     // weight 25%
    let cookingFrequencyMatchScore: Double   // weight 15%
    let cleanlinessMatchScore: Double        // weight 20%
    let smokingPetsMatchScore: Double        // weight 15%

    var overallScore: Double {
        (sleepScheduleMatchScore * 0.25)
        + (noiseToleranceMatchScore * 0.25)
        + (cookingFrequencyMatchScore * 0.15)
        + (cleanlinessMatchScore * 0.20)
        + (smokingPetsMatchScore * 0.15)
    }

    var isRecommended: Bool {
        overallScore >= 60.0
    }

    /// Corresponds to "Potential Differences" in the UI. Must always be shown
    /// in the Match Details screen — never hidden, even when overallScore is high.
    let conflictPoints: [String]
}
```

### 2.6 RoommateProfile

```swift
/// Represents a candidate roommate's public profile, shown to other users
/// during roommate matching and contact.
/// Business Rule: users must be 18 years or older to have a profile on the platform.
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
```

> **Important consequence of this change**: every user — including the
> currently logged-in user (Emily) — has their own `RoommateProfile`, since
> everyone is simultaneously a *viewer* (browsing others) and a *candidate*
> (visible to others). `RoommateProfile` is not exclusively "other people's
> profiles" — it is the one model representing a person on the platform.
>
> This means UC1 (`MatchHousingListingsUseCase`) reads the current user's
> `HousingPreference` via `currentUserRoommateProfile.housingPreference`,
> not from a separate standalone lookup. The Repository layer should expose
> a way to fetch "the current user's own `RoommateProfile`" distinctly from
> "candidate `RoommateProfile`s to match against."

### 2.7 ViewingRequest

```swift
/// Represents a request by a user to schedule an in-person viewing of a listing.
/// Business Rule: requestedTime must be in the future at the time of creation.
/// Business Rule: a user cannot hold more than 3 pending requests at once
/// (enforced in the Use Case layer, since it requires querying across multiple ViewingRequest instances).
/// Business Rule: a user cannot submit more than one request for the same listing
/// within 24 hours (enforced in the Use Case layer, for the same reason).
struct ViewingRequest: Timestamped {
    let requestID: String
    let listingID: String
    let userID: String
    let requestedTime: Date
    var status: ViewingRequestStatus
    let createdAt: Date

    init?(requestID: String, listingID: String, userID: String,
          requestedTime: Date, status: ViewingRequestStatus, createdAt: Date) {
        guard requestedTime > Date() else { return nil }
        self.requestID = requestID
        self.listingID = listingID
        self.userID = userID
        self.requestedTime = requestedTime
        self.status = status
        self.createdAt = createdAt
    }

    var timestamp: Date { createdAt }
}

enum ViewingRequestStatus {
    case pending
    case confirmed
    case declined
    case cancelled
}
```

### 2.8 Message

```swift
/// Represents a single message sent within a conversation thread between two users.
/// Business Rule: a user cannot send more than 5 messages to the same recipient
/// within a 1-minute window (enforced in the Use Case layer).
/// Business Rule: sharedListingID, if set, must reference a listing the sender
/// has already viewed or saved (enforced in the Use Case layer).
struct Message: Timestamped {
    let messageID: String
    let senderID: String
    let recipientID: String
    let content: String
    let sentAt: Date
    let sharedListingID: String?    // optional — set if this message shares a listing

    var timestamp: Date { sentAt }
}
```

---

## 3. Protocols (Protocol-Oriented Design)

Two protocols represent real, shared domain behaviours — not added merely to
demonstrate the pattern.

### RecommendationScoring

Shared responsibility: both `ListingMatchScore` and `CompatibilityScore`
judge whether a candidate (a listing or a person) meets the recommendation
threshold, using the same weighted-average + 60% cutoff logic.

```swift
/// Represents any score that determines whether a candidate
/// (a listing or a person) should be actively recommended to the user.
protocol RecommendationScoring {
    var overallScore: Double { get }
    var isRecommended: Bool { get }
}
```

### Timestamped

Shared responsibility: both `ViewingRequest` and `Message` need to be sorted
or filtered chronologically, and both feed into Use Case business rules that
check a time window (24-hour duplicate check; 1-minute message rate limit).

```swift
/// Represents any domain record that carries a point-in-time creation timestamp,
/// allowing records to be sorted or filtered chronologically.
protocol Timestamped {
    var timestamp: Date { get }
}
```

---

## 4. Design Tokens (from Hi-Fi mockups)

### Color palette

```
Primary (buttons, nav, active tabs):       #2F6B4F
Primary — dark (pressed state):            #1F5546
Primary — mid (secondary emphasis):        #2A5F4E

Accent (match % badges ONLY — never buttons):
  Badge background:                        #FFC857
  Badge dot/icon:                          #7A5A12

Text — primary/headings:                   #23231F
Text — body:                               #3D3D3A
Text — secondary/placeholder:              #8A8A82
Text — tertiary:                           #96968C

Background — page:                        #F7F9F4
Background — card:                        #FFFFFF
Background — tag (Furnished, Pet-friendly etc.): #E7F0E8

Error — border:                           #C0392B
Error — background:                       #FDF0EE

Divider/border (neutral):                 #C6C6BD
Disabled button background:               #E4E4DC
Disabled button text:                     #9A9A90
```

### Layout

```
Card corner radius:      16px
Button corner radius:    15px
Tag/chip corner radius:  8px
Primary button height:   54px
Card shadow:             0 1px 2px rgba(35,35,31,.06), 0 6px 18px rgba(35,35,31,.05)
```

### Important UI rules

- Match percentage badges use ONE consistent treatment everywhere: solid
  amber (#FFC857) pill, dark text, small status dot, specific percentage —
  never used for anything else (buttons, nav, etc.)
- The "Potential differences" section on the Match Details screen must
  always be visible (not collapsed/hidden) and must use a neutral/amber
  callout style, visually distinct from the green "Why you match" section
- Budget validation error state (Screen 8) is a live, real-time inline
  validation — not a submit-time-only check

---

## 5. Screen ↔ Use Case Mapping

| Screen | Use Case(s) |
|---|---|
| 1. Home / listing feed | UC1 |
| 2. AI Match preferences (Find a Home tab) | UC1, UC5 (edits `currentUser.housingPreference`) |
| 2. AI Match preferences (Find a Roommate tab) | UC3, UC5 |
| 3. Roommate match results | UC3 |
| 4. Match details | UC3, UC4 (entry point) |
| 5. Listing detail | UC1 (detail view), UC2 (entry point) |
| 6. Schedule viewing | UC2 |
| 7. Conversation | UC4 |
| 8. Edit preferences | UC5 |

---

## 6. Recommended Development Order

1. **Domain Models** (this doc, section 2) — implement all 8 models.
   Note: `HousingPreference` is composed inside `RoommateProfile`, not a
   standalone top-level model — implement `BudgetRange` and
   `HousingPreference` first, then `RoommateProfile` last since it depends
   on both `LifestyleProfile` and `HousingPreference`
2. **Protocols** (section 3) — retrofit onto models once at least 2 exist
   per protocol
3. **Use Cases** (section 1) — one at a time: happy path → unit tests →
   error handling → fix any bugs found
4. **SwiftUI Views** (section 4 & 5) — one screen at a time, wire to
   ViewModels and Use Cases
5. **Polish** — DocC comments, README, final test pass

Use feature branches per phase (e.g. `feature/domain-models`,
`feature/use-cases`, `feature/views`), merge back to `main` after each phase.
Commit messages follow Conventional Commits (`feat:`, `fix:`, `test:`,
`docs:`, `refactor:`).
