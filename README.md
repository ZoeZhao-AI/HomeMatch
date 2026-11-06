# HomeMatch

A housing and roommate matching iOS app, built for a Solution
Engineering assignment (UTS Master of IT, Enterprise Software Development).
Matching is currently rule-based (weighted scores plus hard requirements),
and is designed so the scoring can later be replaced by an AI model.

## Project Overview

HomeMatch helps university students and young professionals find a home
and compatible roommates in one place. Instead of treating "finding a
place to live" and "finding someone to live with" as two separate
problems, the app scores both against the user's stated preferences and
surfaces the result honestly, including where a potential roommate's
habits don't line up with the user's own, not just where they do.

The app was designed around our primary stakeholders, Uni student in Sydney who are about to graduate searching for an affordable, well
located share house with a compatible flatmate.

## Domain Context

**Domain:** property / housing services, roommate matching.

The core problem this app addresses: people often struggle to find
housing that meets their practical needs (budget, location, room type)
while also finding roommates whose lifestyle and living expectations are
compatible with their own. Traditional listing sites solve the first
half; they rarely help with the second.

HomeMatch's approach is to be transparent about compatibility rather than
just optimistic about it. Every match includes a breakdown of why it
scored the way it did, and a dedicated "Potential differences" section
that is always shown, even for a high-scoring match, so the user goes in
with open eyes rather than a false sense of certainty.

## Architecture Summary

The app follows a layered, domain-driven architecture:

```
SwiftUI Views  ->  ViewModels (MVVM)  ->  Use Cases  ->  Domain Models  ->  Data
```

- **Domain Models** (`HomeMatch/Models`): 8 core models (`HousingListing`,
  `RoommateProfile`, `LifestyleProfile`, `CompatibilityScore`,
  `ListingMatchScore`, `ViewingRequest`, `Message`, and `HousingPreference`,
  the last of which is composed inside `RoommateProfile` rather than
  standing alone, so every model is structurally connected to another).
  Business rules are enforced at the type level wherever possible. For
  example, `BudgetRange`'s failable initializer rejects an invalid range
  before an invalid `HousingPreference` can even be constructed.

- **Protocols:** `RecommendationScoring` (shared by `ListingMatchScore`
  and `CompatibilityScore`, both of which judge whether a candidate meets
  a 60% recommendation threshold) and `Timestamped` (shared by
  `ViewingRequest` and `Message`, both of which need to be sorted or
  filtered by a time window).

- **Use Cases** (`HomeMatch/UseCases`): 5 use cases encapsulate every
  significant business operation: `MatchHousingListingsUseCase`,
  `MatchRoommatesUseCase`, `ScheduleViewingUseCase`,
  `InitiateRoommateContactUseCase`, and `UpdateHousingPreferenceUseCase`.
  Each has a typed, domain-specific error enum with human-readable
  messages, and each is covered by unit tests (happy path, boundary
  conditions, and failure cases).

- **ViewModels** (`HomeMatch/ViewModels`): one per screen, `@MainActor`
  `ObservableObject`s that call the relevant Use Case and expose state
  to the View. Sample/mock data stands in for a real backend, since this
  is an MVP.

- **Views** (`HomeMatch/Views`): 9 SwiftUI screens: Home, AI Match
  preferences (Find a Home / Find a Roommate), Roommate match results,
  Match details, Listing detail, Schedule viewing, Conversation, Edit
  preferences, and Profile.

## Human-System Architecture

A one-page diagram (in the assignment submission) shows the layer
structure above, the human-system boundary, and the primary use case's
data flow. Emily's `LifestyleProfile` flows down into
`MatchRoommatesUseCase`, which returns a `CompatibilityScore` for each
candidate, shown back to Emily on the Match Details screen.

## Setup Instructions

1. Clone the repository and open `HomeMatch.xcodeproj` in Xcode (15+).
2. Select an iOS Simulator as the run destination. No Apple Developer
   Team is required, since signing is not configured and this is a
   simulator-only MVP.
3. Build and run (`Cmd+R`).
4. To run the unit test suite, use `Cmd+U`, or Product then Test.

No external dependencies or package installations are required. The
project uses only Foundation and SwiftUI.

## Testing and Iteration

The two matching use cases were evaluated, fixed, and re-evaluated. **All
evaluation data is synthetic** (generated with fixed random seeds), and
roommate compatibility was judged by **an LLM (Claude Sonnet 5.5) applying
a written rubric**, not by real users. Each result was measured on two
independent data sets: the original seeds (A) and a fresh set (B) with new
seeds and full street addresses.

Changes made after the first evaluation:

- **Housing:** budget maximum, preferred suburb, room type and (when
  required) pet-friendliness became hard requirements for a
  recommendation. Suburbs now match whole names, so "Sydney" no longer
  matches "North Sydney". Listings that break a requirement still appear
  under "Show all".
- **Roommates:** a smoker / non-smoker pair is never recommended. The 60%
  threshold and weights were left unchanged.

| Metric | Before (A / B) | After (A / B) |
|---|---|---|
| Recommended listings breaking budget max, suburb or room type (synthetic, 100 users x 1,000 listings) | 90.0% / 89.6% | 0% / 0% |
| Roommate agreement with LLM judge (synthetic, 200 pairs) | 60.5% / 62.0% | 75.5% / 72.0% |
| Precision vs LLM judge | 37.8% / 33.9% | 49.5% / 41.1% |
| Recall vs LLM judge | 100% / 100% | 100% / 100% |
| Median time to rank 10,000 items on set A, housing / roommates (21 runs, Apple M3 Pro, `-O` build) | 35.8 / 36.7 ms | 34.4 / 37.4 ms |
| Unit tests passing (iOS Simulator) | 26 / 26 | 34 / 34 |
| Line coverage, Use Cases / Models | 90.8% / 95.7% | 91.9% / 93.8% |

Notes: the remaining roommate disagreements are mostly pairs the rubric
rejects for several minor lifestyle differences combined; the app was
deliberately not tuned to copy the rubric. The LLM's labels matched a
mechanical implementation of the same rubric on every pair, so agreement
measures the app against the rubric rather than against real people.

## Known Limitations

- The "Find a Roommate" tab of the Edit Preferences screen does not yet
  persist changes, since there is no `UpdateLifestyleProfileUseCase` in
  the current design. This is a known gap; see the reflective report for
  further discussion.
- Data is currently sourced from in-memory sample/mock data rather than
  a real backend or persistent Repository. This is intentional for the
  scope of this MVP.
- Some screens (e.g. sharing a listing in conversation) use static
  content where a full Repository-backed flow would be needed for a
  production app.

## Author

Ziying (Zoe) Zhao, UTS Master of Information Technology (Enterprise
Software Development)
