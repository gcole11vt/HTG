# Task List

## To Do

- [ ] **Loading screen: Personalized name stamp**
  - Add the locally saved `UserProfile.name` at the lower left, matching the gold HTG stamp. Start in `HTG/Features/Landing/Views/LandingView.swift` and `HTG/App/RootView.swift`; reuse `ShimmeringGoldText`, omit blank names, and avoid network requests or image generation so launch timing stays unchanged.

- [x] **Golf Mode: Settings panel and View option**
  - Add a Golf Mode setting in Profile that opens a new panel.
  - Move "Pre Shot Routine", "Mantra", and "Swing Thoughts" into that panel.
  - Add a new "View" option in the panel with two settings: "Ladder" (the existing view) and "Text" (default).

- [x] **Golf Mode: Text view**
  - When View = Text, remove the ladder and show a layout similar to Clubs -> Print -> By Yardage.
  - Left side: text yardage ladder of club / shot / yardage, initially centered on the yardage of the shot.
  - Right side: Mantra and the other items (Pre Shot Routine, Swing Thoughts).
  - The user can scroll up and down the text ladder while everything else on the page stays the same.

- [x] **Golf Mode: Yardage entry is one tap**
  - Currently, tapping the number, then tapping into the popup above "Go", then typing is too many steps.
  - Change to: one tap on the number opens a blank number pad with a submit button.

- [x] **Golf Mode: Yardage microphone button**
  - In Golf Mode -> Yardage, add a microphone button to the left of the Reset button.
  - It listens for the user to state their yardage and fills it in.

- [x] **Putting mode (new feature, similar to Range and Golf modes)**
  - Purpose: dial in green speeds before the round and use them effectively during play.
  - Default: open to a screen where the user enters the putt distance (feet), then shows a yardage-ladder-style or text-based view (same options as Golf Mode).

- [x] **Putting: Align Speed mode**
  - Walks the user through speed calibration.
  - Initial default: positions 1 through 5, each a backswing length the user takes the putter back to.
  - For each position, the user records the putt distance to dial in how that speed rolls on the course.
  - The calibrated 1-5 (or user/app-defined) speeds then drive putt suggestions on the main view, similar to club suggestions.
  - Open question: exact setup flow and whether the position count is user-configurable.

- [x] **Profile: Golf Mode cleanup and Swing Thoughts toggle**
  - In Profile -> Golf Mode, the View section is covered by a bar saying "Also used in putting". Remove it, since it is unnecessary.
  - Add a "Show in Golf Mode" toggle to Swing Thoughts.

- [x] **Golf Mode: Text view border**
  - When View = Text, remove the border around the section to make it look cleaner.

- [x] **Putting: Rename position**
  - In Align mode, add a rename button to the far right of the Position header row.
  - In Putting mode, tapping the name of a position opens a rename panel.

- [x] **Range session: Save button when no entry**
  - Bug: on the first save of a Range session, the median populates, but the "Save" button is greyed out and cannot be pressed.
  - Always keep the "Save" button available. If there is no entry, tapping Save should not save and should show an error instead.

- [ ] **Tiers: Free, Trial, and Paid status classes**
  - Set up the app to handle a free tier and a paid tier. In the current state, do not set up or commit to a single payment platform; just have two classes of status.
  - We may technically need three tiers: free, initial trial, and paid.
  - Use "free" and "paid" as working names for now. Final names will be chosen later (e.g., "Muni" and "Country Club"), so do not lock them in.
  - Keep the tier names in one place, separate from the internal status values, so renaming them later is a single-file change.

- [ ] **Paid gating: Clubs shot types**
  - Free tier: 1 or 2 shot types per club.
  - Paid tier: up to 10 shot types per club.

- [ ] **Paid gating: Range Mode shot types**
  - Make sure the shot types set up for Range Mode align with the Clubs tier status.

- [ ] **Paid gating: Continuous voice logging in Range Mode**
  - Paid tier only. Free tier gets an initial 14 days.

- [ ] **Paid gating: Swing Thoughts by Club**
  - All Swing Thoughts by Club is available in the free tier.
  - Delegating a club is paid tier only.

- [ ] **Paid gating: Putting**
  - Paid tier only. Free tier gets Putting for 14 days.

- [ ] **Paid gating: Formatted yardage printing**
  - Paid tier only.

- [ ] **Paid gating: Cloud backup and sync**
  - Paid tier only.

- [ ] **New feature: Saved practice history and club yardages (database only)**
  - Do not build the GUI now. Build the data layer into the database.
  - Dashboard is a premium online feature.

- [ ] **New feature: Bag Gaps (paid)**
  - Highlight where club yardages could be wrong, or where there is an opportunity for a club replacement.
  - Gap highlighting should flag gaps that are too big or too small between clubs.

- [ ] **New feature: Reusable putting calibrations (paid, database only)**
  - Store date, course, and calibration information for reuse.
  - Do not build the GUI now.

- [ ] **New feature: Distance Reliability (paid)**
  - Addition to Range Mode. The user selects Estimate or Monitor, and the choice is stored.
  - Purpose: help the user judge confidence in a yardage estimate.

- [ ] **New feature: Multiple Bags (paid)**
  - Purpose: support players with multiple sets of clubs.
  - Bags can be named, and the user can easily swap which bag is active.
  - Use cases:
    - Someone who lives in both Florida and Salt Lake City and carries clubs between them, where yardages vary widely by location.
    - Someone with a set of blades and a set of more forgiving clubs who rotates between them for fun.

## In Progress

- [ ] 
