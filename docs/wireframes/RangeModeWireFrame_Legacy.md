# Range Mode Wireframe Mapping (Legacy Baseline)

## Purpose
This document captures the current Range Mode legacy wireframe implementation at box/subcomponent level, including hardcoded style hotspots and behavior couplings that must be preserved during refactor.

## Source Files
- `HTG/Features/RangeMode/Views/RangeModeView.swift`
- `HTG/Features/RangeMode/ViewModels/RangeManager.swift`
- `HTG/UIComponents/Theme/GTCColor.swift`
- `HTG/UIComponents/Theme/JournalTheme.swift`

## Legacy Style Profile Summary
- UI composition is monolithic inside `RangeModeView`.
- Styling uses mostly system SwiftUI controls and text styles.
- `GTCColor` is used selectively for accents, secondary labels, warning icon, and save buttons.
- `JournalTheme` is not used in legacy Range Mode.

---

## Wireframe Boxes

### 1) Range Root Container
- **Box Name:** Range Mode root navigation shell.
- **Base settings:** `NavigationStack` containing `VStack(spacing: 20)`; default system screen background.
- **Placement:** Range tab root content.
- **Interaction/clickability:** State-driven switch between start-session and active-session branches.
- **Subcomponents:**
  - Navigation title: `"Range Mode"` (system nav chrome).
  - Start session branch when no active session.
  - Active session branch when `rangeManager.currentSession` exists.
- **Dependencies:** `rangeManager.currentSession`, `clubManager` data loading, and navigation preselection logic.
- **Style source tags:** Mostly system defaults; partial `GTCColor`.
- **Compatibility notes:** Requires structural split into reusable boxes to match Golf Mode composition style.

### 2) Start Session Container
- **Box Name:** Session setup panel.
- **Base settings:** `VStack(spacing: 20)` + outer `.padding()`, no custom card/border shell.
- **Placement:** Main body when there is no active session.
- **Interaction/clickability:** Fully interactive form.
- **Subcomponents:**
  - Title text:
    - `"Start a Range Session"`
    - `.font(.title2)` + `.fontWeight(.semibold)` (system typography).
  - Club picker:
    - `.pickerStyle(.menu)`, includes "Select Club" placeholder.
  - Shot type picker (conditional after club selection):
    - `.pickerStyle(.menu)` + "Other" option.
    - Selection change may raise max shot-type alert.
  - Custom shot type text field (when "Other"):
    - `.textFieldStyle(.roundedBorder)`.
  - Primary action button:
    - `"Start Session"` with `.buttonStyle(.borderedProminent)`.
    - Disabled based on shot type rules and custom name validation.
  - Empty clubs fallback:
    - `ContentUnavailableView` with `bag.fill`.
- **Dependencies:** `clubManager.clubs`, `selectedClub`, `shotTypeSelection`, `customShotTypeName`, `ClubDataService.maximumShotTypesPerClub`.
- **Style source tags:** System controls + selective `GTCColor` in alert/body copy.
- **Hardcoded hotspots:** Spacing `20`; generic title style not mapped to shared feature typography.
- **Compatibility notes:** Can map directly to Golf-like section rhythm after component extraction.

### 3) Active Session Container
- **Box Name:** Active session screen body.
- **Base settings:** `VStack(spacing: 16)` + `.padding()`; tap-to-dismiss keyboard via full content shape.
- **Placement:** Main body during an active session.
- **Interaction/clickability:** Contains all input, save/end actions, stats, and shot history interactions.
- **Subcomponents (order):**
  - Session header
  - Shot entry row
  - Session action buttons row
  - Two-column region (shots list + stats)
  - Save sheet and discard alert overlays
- **Dependencies:** `RangeSession`, `RangeManager` stats and callbacks.
- **Style source tags:** System layout + selective `GTCColor`.
- **Hardcoded hotspots:** Spacing `16`; modal detent and width constants handled in nested boxes.
- **Compatibility notes:** Equivalent to Golf page shell but currently less tokenized and less modular.

### 4) Session Header Box
- **Box Name:** Club and shot type header.
- **Base settings:** Minimal `VStack` with default no border/background.
- **Placement:** Top of active-session container.
- **Interaction/clickability:** Read-only.
- **Subcomponents:**
  - Club name: `.font(.title2)` + `.fontWeight(.bold)`.
  - Shot type label: `.font(.subheadline)` + `GTCColor.secondary`.
- **Dependencies:** `session.clubName`, `session.shotTypeName`.
- **Style source tags:** System typography + `GTCColor.secondary`.
- **Hardcoded hotspots:** No reusable style token for title/subtitle pairing.
- **Compatibility notes:** Strong candidate to map to Golf recommendation/title typography pattern.

### 5) Shot Entry Row Box
- **Box Name:** Distance input and add-shot controls.
- **Base settings:** `HStack(spacing: 12)`.
- **Placement:** Below session header.
- **Interaction/clickability:** Editable distance text and add action.
- **Subcomponents:**
  - Distance field:
    - Placeholder `"Distance"`, number pad keyboard
    - `.textFieldStyle(.roundedBorder)`
    - `.frame(width: 100)`
  - Add button:
    - `"Add Shot"`, `.buttonStyle(.borderedProminent)`
    - Disabled when text empty.
- **Dependencies:** `distanceText`, focus state, `addShot()` action.
- **Style source tags:** Pure system controls.
- **Hardcoded hotspots:** Input width `100`.
- **Compatibility notes:** Can map to Golf micro-control styling and shared input tokens.

### 6) Session Action Buttons Box
- **Box Name:** End/save action row.
- **Base settings:** `HStack(spacing: 12)` with two full-width buttons.
- **Placement:** Below shot entry row.
- **Interaction/clickability:** Opens discard alert and save sheet.
- **Subcomponents:**
  - End session:
    - `.buttonStyle(.bordered)`
  - Save session:
    - `.buttonStyle(.borderedProminent)`
    - `.tint(GTCColor.primary)`
    - Disabled when shot count is zero.
- **Dependencies:** `rangeManager.currentStats.count`, save default distance generation.
- **Style source tags:** System button styles + `GTCColor.primary`.
- **Hardcoded hotspots:** Horizontal spacing and full-width behavior inline.
- **Compatibility notes:** Direct mapping candidate to Golf primary/secondary action treatment.

### 7) Two-Column Session Region Box
- **Box Name:** History-and-stats split panel.
- **Base settings:** `HStack(alignment: .top, spacing: 12)` with vertical divider and fixed stats width.
- **Placement:** Lower half of active-session container.
- **Interaction/clickability:** Left column is interactive list; right is read-only stats.
- **Subcomponents:**
  - Previous shots list column (flex width).
  - Divider.
  - Stats column with fixed `.frame(width: 80)`.
- **Dependencies:** `session.shots`, `rangeManager.currentStats`, `rangeManager.currentCarryDistance`.
- **Style source tags:** Mostly system controls; section labels use `GTCColor.secondary`.
- **Hardcoded hotspots:** Stats width `80`, inter-column spacing `12`.
- **Compatibility notes:** Must be remapped if target parity requires Golf two-column visual language and shared card shells.

### 8) Previous Shots List Box
- **Box Name:** Prior shot history list.
- **Base settings:** Left-aligned `VStack(spacing: 0)` with uppercase section label.
- **Placement:** Left side of two-column region.
- **Interaction/clickability:** Row delete button and swipe delete enabled.
- **Subcomponents:**
  - Section label:
    - `"PREVIOUS SHOTS"`
    - `.font(.caption)` semibold, `GTCColor.secondary`, bottom padding `8`.
  - `List(.plain)` of sorted shots:
    - Distance text: `.font(.body)` in default foreground.
    - Voice marker icon when `shot.isFromVoice`: `mic.fill` with `.font(.caption2)` and `GTCColor.secondary`.
    - Trailing delete button: `trash` icon with `GTCColor.warning`.
    - Swipe delete fallback via `.onDelete`.
- **Dependencies:** Session shot ordering by date descending; delete actions call async range manager methods.
- **Style source tags:** System list + partial `GTCColor`.
- **Hardcoded hotspots:** Section padding `8`; mixed row typography not centralized.
- **Compatibility notes:** Can map to Golf row cards/chips if list style is replaced with custom stack rows.

### 9) Stats Column Box
- **Box Name:** Session metrics panel.
- **Base settings:** `VStack(alignment: .leading, spacing: 12)` with static label+value mini-blocks.
- **Placement:** Right side of two-column region.
- **Interaction/clickability:** Read-only.
- **Subcomponents:**
  - Section label:
    - `"STATS"` in `.caption` semibold, `GTCColor.secondary`.
  - Optional "Current" metric in `GTCColor.primary`.
  - Count/Median/Max/75th metrics with shared helper:
    - Label: `.caption2`, `GTCColor.secondary`
    - Value: `.title3` semibold, default `GTCColor.text` unless override.
- **Dependencies:** `rangeManager.currentStats` and `rangeManager.currentCarryDistance`.
- **Style source tags:** System typography + `GTCColor`.
- **Hardcoded hotspots:** Stack spacing `12`, label/value spacing `2`.
- **Compatibility notes:** Candidate for reusable metric tile style aligned with Golf hierarchy.

### 10) Save Session Sheet Box
- **Box Name:** Carry-distance save modal.
- **Base settings:** Sheet with detent height `320`, drag indicator visible; `VStack(spacing: 16)` and center-aligned entry row.
- **Placement:** Modal overlay from active session save action.
- **Interaction/clickability:** Editable carry distance, save action, tap outside text field to dismiss keyboard.
- **Subcomponents:**
  - Title: `"Save Carry Distance"` in `.headline`.
  - Numeric text field:
    - `.font(.system(size: 48, weight: .bold))`
    - `GTCColor.text`, centered text
    - Width `160`.
  - Save button:
    - `.buttonStyle(.borderedProminent)`
    - `.tint(GTCColor.primary)`
    - `.padding(.horizontal, 40)`
    - Disabled by validation helper.
- **Dependencies:** `saveDistanceText` default/validation methods from `RangeManager`; save action resets selection state.
- **Style source tags:** System modal + inline typography + `GTCColor`.
- **Hardcoded hotspots:** Font size `48`, width `160`, button horizontal padding `40`, detent `320`.
- **Compatibility notes:** Strong mapping candidate to Golf yardage edit sheet styling (`JournalTheme` and shared modal metrics).

### 11) Alerts and Permission Messaging Box
- **Box Name:** Session constraint and permission alerts.
- **Base settings:** System `alert` presentations.
- **Placement:** Root-level overlays.
- **Interaction/clickability:** Dismiss-only or confirm/cancel.
- **Subcomponents:**
  - Max shot types alert (`"Maximum Shot Types"`).
  - Mic permission denied alert (`"Microphone Access Required"`).
  - Discard session confirmation alert with destructive path.
- **Dependencies:** form validation and speech authorization outcomes.
- **Style source tags:** System alert chrome.
- **Compatibility notes:** Behavior-critical; styling generally remains system-standard.

### 12) Voice Input Logic (Hidden Interaction Box)
- **Box Name:** Speech recognition integration path.
- **Base settings:** `SpeechRecognitionService` state is present in view model state graph.
- **Placement:** Non-visible behavior layer attached to active session.
- **Interaction/clickability:** `toggleSpeechMode()` exists but has no visible UI trigger in current layout.
- **Subcomponents:**
  - Authorization request flow.
  - Continuous mode callbacks:
    - Add shot from voice distance.
    - Delete last shot command.
    - Stop command.
- **Dependencies:** permission state, `rangeManager`, and service callback wiring.
- **Style source tags:** N/A (logic only).
- **Compatibility notes:** Refactor should either add styled mic affordance or remove dead-path wiring.

---

## Hardcoded Styling Hotspot Register
- Layout constants:
  - Root/start spacing `20`
  - Active spacing `16`
  - Row spacing `12`
  - Stats label/value spacing `2`
- Fixed dimensions:
  - Distance field width `100`
  - Stats column width `80`
  - Save field width `160`
  - Save button horizontal padding `40`
  - Save sheet detent height `320`
- Typography literals:
  - Start title `.title2`
  - Session title `.title2` + bold
  - Save numeric input `.system(size: 48, weight: .bold)`
  - Section labels `.caption`/`.caption2`
- System control reliance:
  - `.pickerStyle(.menu)`
  - `.textFieldStyle(.roundedBorder)`
  - `.buttonStyle(.bordered/.borderedProminent)`
  - `.listStyle(.plain)`

## Legacy Interaction Couplings To Preserve
- Start session validation and "Other" shot-type flow.
- Save session updates shot type carry distance and closes session context.
- Delete behavior parity between trash icon and swipe action.
- Session end confirmation destructive path.
- Stats and list updates must remain synchronous with added/deleted shots.

---

## Migration Strategy: Legacy Range -> Shared Style Defaults

## Centralization Rule
All final Range Mode styling must resolve through shared defaults (token layer + reusable view styles). No page-level hardcoded colors, fonts, spacing, corner radius, or fixed control widths should remain in `RangeModeView`.

## Token Mapping (Direct Conversion Matrix)
| Legacy usage in Range | Current value/type | Shared default target |
|---|---|---|
| Save button tint | `GTCColor.primary` | Keep `GTCColor.primary` (already aligned) |
| Warning delete icon | `GTCColor.warning` | Keep `GTCColor.warning` (already aligned) |
| Secondary labels | `GTCColor.secondary` | Keep `GTCColor.secondary` |
| Numeric save text | `GTCColor.text` + `.system(size: 48, weight: .bold)` | `GTCColor.primary` or `text` + shared numeric font token (`JournalTheme` extension for entry-size numeric text) |
| Screen titles (`.title2`/`.subheadline`) | System typography | Map to `JournalTheme` title/subtitle equivalents |
| Section labels (`.caption`/`.caption2`) | System typography | Map to shared eyebrow/tokenized helper (same pattern used by Golf section labels) |
| Input field width `100` and save width `160` | Hardcoded frame widths | Move to shared layout constants for compact/expanded numeric inputs |
| Sheet detent `320` | Hardcoded modal dimension | Move to shared modal metrics token used by Golf and Range |
| Stats column width `80` | Hardcoded column width | Move to shared dashboard metric panel width token |

## Component Mapping (Range Box -> Golf-Style Equivalent)
| Legacy Range box | Golf reference pattern | Refactor target |
|---|---|---|
| Root `NavigationStack` layout | `YardageBookPageView` section rhythm | Keep navigation if required, but adopt Golf-like section spacing and horizontal rhythm tokens |
| Session header | `PageTitleView` + recommendation heading style | New `RangeSessionHeaderView` with tokenized typography |
| Shot entry row | `YardageDisplayView` control surfaces | New `RangeShotEntryView` using shared input/button style wrappers |
| Action button row | Golf primary/secondary button hierarchy | New `RangeSessionActionsView` with shared button style defaults |
| Two-column split + stats | Golf page two-column parity from redesign docs | New `RangeSessionContentSplitView` with tokenized widths/spacing |
| Previous shots list | Golf row/chip treatment patterns (`ClubShotRowView` family) | New custom shot row component replacing plain `List` styling if visual parity required |
| Stats stack | Golf concise data blocks | New `RangeStatsColumnView` with reusable metric item style |
| Save sheet | Golf yardage edit sheet pattern in `YardageDisplayView` | New shared `CarryDistanceSheetView` reusing modal dimensions/typography defaults |

## Phased Conversion Plan

### Phase A: Token Parity and Documentation Lock
1. Define shared Range-compatible typography and layout tokens (extend `JournalTheme` and/or add layout constants adjacent to theme files).
2. Replace all explicit system typography/size literals in Range UI with named tokens.
3. Replace magic dimensions (`100`, `80`, `160`, `320`, button padding) with named shared metrics.
4. Keep behavior unchanged while style references are centralized.

### Phase B: Structural Component Extraction
1. Split `RangeModeView` into focused subviews matching the box map:
   - start session
   - active session header
   - shot entry
   - session actions
   - shot history list
   - stats column
   - save sheet
2. Each subview consumes shared defaults only; no local ad-hoc style literals.
3. Preserve all interaction couplings from the legacy register.

### Phase C: Visual Parity and Hardcode Removal Audit
1. Compare each refactored Range box against Golf reference patterns in `GolfModeWireFrame.md`.
2. Run a hardcode audit pass on Range files for:
   - direct `.system(size:)` typography usage
   - hardcoded frame dimensions and paddings
   - ad-hoc colors/system semantic color drift
3. Approve parity only when Range visuals are token-driven and cross-box interactions remain intact.

## Implementation Readiness Checklist
- Every Range box has a one-to-one target style mapping.
- Token matrix defines where each legacy style lands in shared defaults.
- Conversion sequence isolates behavior from visual change to reduce regression risk.
- No migration step requires hardcoding style values in feature-specific pages.
