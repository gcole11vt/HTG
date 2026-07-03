# Club Management Wireframe Mapping (Legacy Baseline)

## Purpose
This document captures the current Club Management wireframe implementation at box/subcomponent level, including style hotspots and interaction couplings that must be preserved during refactor to Golf Mode visual patterns.

## Source Files
- `HTG/Features/ClubManagement/Views/ClubListView.swift`
- `HTG/Features/ClubManagement/ViewModels/ClubManager.swift`
- `HTG/Core/Services/ClubDataService.swift`
- `HTG/Features/Profile/ViewModels/ProfileManager.swift`
- `HTG/Core/Services/NavigationCoordinator.swift`
- `HTG/UIComponents/Theme/GTCColor.swift`
- `HTG/UIComponents/Theme/JournalTheme.swift`

## Legacy Style Profile Summary
- UI composition is mostly list/form-driven system controls with local style literals.
- `GTCColor` is applied for secondary labels, swipe/archive/restore tints, warning accents, and delta chips.
- `JournalTheme` is available globally but not used in Club Management UI.
- Most typography, spacing, and control shapes rely on SwiftUI defaults (`.headline`, `.body`, `.caption`, `.roundedBorder`, `.borderedProminent`, `.listStyle` defaults).

---

## Wireframe Boxes

### 1) Club Mode Root Container
- **Box Name:** Club Management root navigation shell.
- **Base settings:** `NavigationStack` hosting a `List` with inline sections and conditional content blocks.
- **Placement:** Clubs tab root content.
- **Interaction/clickability:** State-driven rendering for loading, empty, and populated club states.
- **Subcomponents:**
  - Active clubs collection.
  - Archived clubs section (conditional).
  - Navigation destination to detail view.
  - Top-right add button and add-club sheet.
  - Error alert overlay.
- **Dependencies:** `clubManager.clubs`, `clubManager.archivedClubs`, `clubManager.isLoading`, `clubManager.errorMessage`, profile-driven primary shot type.
- **Style source tags:** System list/navigation + selective `GTCColor`.
- **Compatibility notes:** Equivalent to Range/Golf root shells; should be split into tokenized subviews in refactor.

### 2) Active Club List Region
- **Box Name:** Active club rows list.
- **Base settings:** Plain `ForEach` rows in primary `List` body.
- **Placement:** Top of root list when active clubs exist.
- **Interaction/clickability:** Row tap enters detail; trailing swipe archives club.
- **Subcomponents:**
  - `NavigationLink` wrapping each row.
  - `ClubRowView` with leading club name and trailing computed distance.
  - Archive swipe action button (`archivebox`) tinted `GTCColor.swipe`.
- **Dependencies:** Clubs sorted descending by resolved display distance using `ClubDistanceResolver`.
- **Style source tags:** System row style + `GTCColor.swipe`/`secondary`.
- **Hardcoded hotspots:** Uses `.font(.headline)` for name and default list row chrome.

### 3) Root Empty and Loading States
- **Box Name:** Clubs root fallback states.
- **Base settings:** Inline conditional branch in list body.
- **Placement:** Replaces active rows when there are no clubs.
- **Interaction/clickability:** Read-only status content.
- **Subcomponents:**
  - Loading state: `ProgressView("Loading clubs...")`.
  - Empty state: `ContentUnavailableView("No Clubs", systemImage: "bag.fill", description: "Add clubs to get started")`.
- **Dependencies:** `clubManager.isLoading`, `sortedClubs.isEmpty`.
- **Style source tags:** System defaults (no custom card, border, or type tokens).

### 4) Archived Clubs Section
- **Box Name:** Archived clubs list section.
- **Base settings:** `Section("Archived")` with muted row styling.
- **Placement:** Below active/empty region when archived clubs exist.
- **Interaction/clickability:** Trailing swipe restore action.
- **Subcomponents:**
  - `ClubRowView` with `.foregroundStyle(GTCColor.secondary)`.
  - Restore swipe button (`arrow.uturn.backward`) tinted `GTCColor.primary`.
- **Dependencies:** `clubManager.archivedClubs`.
- **Style source tags:** System section/list + `GTCColor.secondary`/`primary`.
- **Compatibility notes:** Should map to reusable archived row treatment shared across features.

### 5) Club Row Item
- **Box Name:** Reusable club summary row.
- **Base settings:** `HStack` with text + spacer + distance value.
- **Placement:** Active and archived rows.
- **Interaction/clickability:** Parent controls navigation/swipe interactions.
- **Subcomponents:**
  - Club name: `.font(.headline)`.
  - Distance text: `"\(resolvedDistance) yds"` with `GTCColor.secondary`.
- **Dependencies:** `ClubDistanceResolver.resolveDisplayDistance(...)`.
- **Style source tags:** System typography + `GTCColor.secondary`.
- **Hardcoded hotspots:** No shared typography tokens; hardcoded value string format.

### 6) Club Detail Root Container
- **Box Name:** Club detail list shell.
- **Base settings:** `List` with multiple sections and editing mode toggles.
- **Placement:** `navigationDestination` from root list row tap.
- **Interaction/clickability:** Section-specific editing, swiping, and sheet launch.
- **Subcomponents (order):**
  - Club name + nickname section.
  - Shot types section.
  - Archived shot types section (conditional).
  - Swing thoughts section.
  - Add shot type sheet.
  - Top-right range navigation button.
- **Dependencies:** `club`, `clubManager`, `primaryShotType`, `navigationCoordinator`, async state for profile/swing thoughts.
- **Style source tags:** System list/forms + selective `GTCColor`.
- **Compatibility notes:** Monolithic detail UI should be componentized into token-driven cards/rows.

### 7) Club Name and Nickname Section
- **Box Name:** Club identity edit section.
- **Base settings:** `Section("Club Name")` with two independent inline edit flows.
- **Placement:** Top section in detail list.
- **Interaction/clickability:** "Edit" toggles to text fields + save buttons.
- **Subcomponents:**
  - Club name display row and editable row.
  - Nickname display row with helper label `"Nickname"` in `GTCColor.border` and italics.
  - Nickname text filtering (alphanumeric, max 2 chars).
  - Save buttons with `.buttonStyle(.borderedProminent)`.
- **Dependencies:** `clubManager.updateClub(...)` async operations.
- **Style source tags:** System form controls + `GTCColor.border`.
- **Hardcoded hotspots:** No shared edit-field or save-button token wrappers.

### 8) Shot Types Section
- **Box Name:** Active shot types panel.
- **Base settings:** `Section("Shot Types")` with swipe actions and inline add button.
- **Placement:** Under identity section.
- **Interaction/clickability:** Tap row to edit; leading swipe routes to Range; trailing swipe archives.
- **Subcomponents:**
  - `ShotTypeRowView` rows for active shot types.
  - Leading swipe `"Range"` action tinted `GTCColor.primary`.
  - Trailing destructive archive action.
  - Conditional add-shot-type button (`sortedShotTypes.count < 5`).
- **Dependencies:** Active shot type list, primary shot type matching, shot type count limits.
- **Style source tags:** System section/list + `GTCColor.primary`.
- **Compatibility notes:** Should map to standardized action-row pattern and reusable swipe affordances.

### 9) Shot Type Row (Display + Edit States)
- **Box Name:** Shot type detail row with delta indicator.
- **Base settings:** Two-state row (`displayContent`/`editingContent`), both built with `HStack`.
- **Placement:** Inside active shot types section.
- **Interaction/clickability:** Tap display row enters edit mode; save commits name/distance updates.
- **Subcomponents:**
  - Display state:
    - Name with bold for primary type.
    - Optional delta capsule for non-primary distance differences.
    - Distance text in `GTCColor.secondary`.
  - Delta capsule:
    - Text `.font(.caption).fontWeight(.semibold)`.
    - Positive fill `GTCColor.deltaPositiveBackground` + text `GTCColor.primary`.
    - Negative fill `GTCColor.deltaNegativeBackground` + text `GTCColor.warning`.
  - Edit state:
    - Name + distance text fields with `.roundedBorder`.
    - Distance field fixed width `80`, number pad keyboard.
    - Save button `.borderedProminent`.
- **Dependencies:** `clubManager.updateShotType(...)`, primary distance resolution.
- **Style source tags:** System controls + `GTCColor` derived tokens.
- **Hardcoded hotspots:** Width `80`, inline capsule paddings, system typography literals.

### 10) Archived Shot Types Section
- **Box Name:** Archived shot types panel.
- **Base settings:** `Section("Archived")` with muted rows and restore action.
- **Placement:** Below active shot types section when archived entries exist.
- **Interaction/clickability:** Trailing swipe restore for each shot type.
- **Subcomponents:**
  - Name + distance row with `GTCColor.secondary` styling.
  - Restore swipe button tinted `GTCColor.primary`.
- **Dependencies:** `archivedShotTypes` computed list.
- **Style source tags:** System list/section + `GTCColor`.

### 11) Swing Thoughts Section
- **Box Name:** Club-tagged swing thought manager.
- **Base settings:** `Section("Swing Thoughts")` containing list/read-empty/add form flow.
- **Placement:** Bottom of detail list.
- **Interaction/clickability:** Row deletion, text entry, add action.
- **Subcomponents:**
  - Empty message in `GTCColor.secondary`.
  - Existing thought rows with `.onDelete`.
  - Input row: text field + add button, disabled when trimmed input empty.
- **Dependencies:** `ProfileManager` load/add/delete and filter (`tagType == "club"` and `tagValue == club.name`).
- **Style source tags:** System section/form + `GTCColor.secondary`.
- **Compatibility notes:** Candidate for shared note-list component patterns from Golf supporting sections.

### 12) Add Club Sheet
- **Box Name:** New club creation modal.
- **Base settings:** `NavigationStack` + `Form` with cancel/add toolbar actions.
- **Placement:** Sheet launched from root plus button.
- **Interaction/clickability:** Form input with live nickname generation and validation.
- **Subcomponents:**
  - Club name field updates nickname auto-generated from `NicknameGenerator`.
  - Nickname field with uppercase and 2-char alphanumeric clamp.
  - Default distance numeric field.
  - Add button disabled for incomplete values.
- **Dependencies:** `clubManager.addClub(...)`, `ClubDataService.maximumClubs`.
- **Style source tags:** System form and toolbar controls.
- **Hardcoded hotspots:** Default distance seed `"150"` and generic system form styling.

### 13) Add Shot Type Sheet
- **Box Name:** New shot type modal.
- **Base settings:** `NavigationStack` + `Form` with cancel/add toolbar actions.
- **Placement:** Sheet launched from shot types section.
- **Interaction/clickability:** Name + distance entry, validation, async add.
- **Subcomponents:**
  - Shot type name field.
  - Numeric distance field.
  - Add button disabled for empty inputs.
- **Dependencies:** `clubManager.addShotType(...)`, per-club max shot type limits.
- **Style source tags:** System form and toolbar controls.

### 14) Toolbar + Navigation Actions
- **Box Name:** Cross-feature navigation affordances.
- **Base settings:** Toolbar buttons in root and detail nav bars.
- **Placement:** Top-right toolbar slots.
- **Interaction/clickability:** Root plus opens add sheet; detail "Range" button routes tabs.
- **Subcomponents:**
  - Root plus icon button (`Image(systemName: "plus")`).
  - Detail "Range" text button invoking `navigationCoordinator.navigateToRange(...)`.
- **Dependencies:** `NavigationCoordinator` preselection state (`clubName`, optional `shotTypeName`, auto-start flag).
- **Style source tags:** System toolbar buttons.

### 15) Alerts and Error Messaging
- **Box Name:** Club operation error alert.
- **Base settings:** System `alert("Error", isPresented: ...)`.
- **Placement:** Root list overlay.
- **Interaction/clickability:** Dismiss-only (`OK`) clears error state.
- **Subcomponents:**
  - Alert title `"Error"`.
  - Dynamic message from `clubManager.errorMessage`.
- **Dependencies:** Errors bubbled from `ClubManager`/`ClubDataService` guardrails:
  - max clubs reached,
  - max shot types reached,
  - minimum one active shot type required,
  - generic persistence failures.
- **Style source tags:** System alert chrome.

---

## Cross-Box Interaction Dependencies
- Club list ordering and displayed distances depend on profile-selected primary shot type.
- Editing shot type distances updates delta chip logic in the same render path.
- Archive/restore flows in both clubs and shot types refresh list snapshots through `loadClubs()`.
- Detail "Range" swipes and toolbar actions both depend on `NavigationCoordinator` preselection channels.
- Swing thoughts in detail are scoped to club name tags; changing names affects downstream filtering assumptions.

## Hardcoded Styling Hotspot Register
- Typography literals:
  - `.font(.headline)` for club names.
  - `.font(.caption)` for shot deltas.
  - default body styles for many section/value labels.
- Layout/dimension literals:
  - Distance edit field width `80`.
  - Delta chip paddings (`horizontal 6`, `vertical 2`).
  - Local list/form spacings implicit in system defaults (not tokenized).
- Control-style reliance:
  - `.textFieldStyle(.roundedBorder)`.
  - `.buttonStyle(.borderedProminent)`.
  - Default `List`/`Section` chrome.
- Color coupling outside reusable wrappers:
  - Inline `GTCColor.secondary`, `primary`, `warning`, `border`, `swipe` usage.

## Legacy Interaction Couplings To Preserve
- Primary shot type affects sort order and distance display context across club and shot rows.
- Shot type archive guardrail: club cannot drop below one active shot type.
- Club and shot type count limits must continue surfacing user-facing errors.
- Nickname generation/filtering behavior in add/edit flows must remain intact.
- Range navigation preselection must preserve selected club and optional shot type.

---

## Migration Strategy: Legacy Club -> Shared Style Defaults

## Centralization Rule
All final Club Management styling should resolve through shared defaults (token layer + reusable view styles). No page-level hardcoded colors, fonts, spacing, corner radius, or control widths should remain in Club feature views.

## Token Mapping (Direct Conversion Matrix)
| Legacy usage in Club | Current value/type | Shared default target |
|---|---|---|
| Club/shot name title text | `.headline` / `.body` system fonts | `JournalTheme` named title/body tokens for lists and detail rows |
| Delta badge text/chrome | `.caption` + inline paddings + capsule | Shared delta badge component tokenizing text size, paddings, fills |
| Secondary labels/distances | `GTCColor.secondary` inline usage | Keep `GTCColor.secondary`, but apply via shared row style wrappers |
| Archive swipe tint | `GTCColor.swipe` | Keep token, consume through reusable swipe action style helper |
| Restore/range action tint | `GTCColor.primary` | Keep token, consume through shared action style helper |
| Warning/destructive accents | `GTCColor.warning` | Keep token and centralize via semantic destructive style token |
| Input/control styles | `.roundedBorder` / `.borderedProminent` | Shared field/button modifiers for Club/Range/Profile parity |
| Distance edit width | `80` | Shared numeric-input width token |
| Form/list spacing/chrome | System defaults | Shared section rhythm tokens (matching Golf page spacing intent) |

## Component Mapping (Club Box -> Golf-Style Equivalent)
| Legacy Club box | Golf reference pattern | Refactor target |
|---|---|---|
| Root list shell | Golf page scaffold rhythm | New `ClubManagementRootView` with explicit section spacing/layout tokens |
| Club row | Golf supporting rows/chips | New reusable `ClubSummaryRowView` with tokenized typography/colors |
| Shot type row + delta chip | Golf recommendation metadata chips | Reusable `ShotTypeRowCardView` with shared badge/action styling |
| Archived sections | Golf secondary/supporting info tone | Reusable `ArchivedItemsSectionView` with consistent muted treatments |
| Inline edit rows | Golf micro-control treatments | Shared editable row controls with tokenized fields/buttons |
| Add Club/Add Shot sheets | Golf yardage edit sheet conventions | Shared modal metrics + field/button style defaults |
| Swing thoughts list | Golf supporting note blocks | Shared note-row/list style component |

## Phased Conversion Plan

### Phase A: Token Parity and Documentation Lock
1. Add/extend shared typography and layout tokens for Club list rows, delta badges, numeric inputs, and section rhythm.
2. Replace Club-level typography and dimension literals with named shared defaults.
3. Keep behavior unchanged while centralizing style references.

### Phase B: Structural Component Extraction
1. Split monolithic `ClubListView` and detail sections into focused reusable views.
2. Move recurring styles into shared modifiers/components.
3. Preserve all archive/restore/edit/navigation behavior couplings.

### Phase C: Visual Parity and Hardcode Removal Audit
1. Compare Club components against Golf reference motifs and spacing hierarchy.
2. Audit for remaining hardcoded `.font(...)`, width literals, and ad-hoc style expressions.
3. Approve parity only when Club UI styling is token-driven and behavior remains unchanged.

## Implementation Readiness Checklist
- Every Club box has a one-to-one target style mapping.
- Hardcoded style literals and dimensions are cataloged with target tokens.
- Behavior-critical couplings are explicitly preserved in migration steps.
- Conversion sequence isolates style changes from behavioral logic changes.
