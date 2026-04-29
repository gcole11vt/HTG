# Golf Mode Wireframe Mapping

## Purpose
This document maps the current Golf Mode wireframe implementation into box-level style definitions and subcomponent behavior so it can be used as the reference style system for Range Mode refactoring.

## Source Files
- `HTG/Features/GolfMode/Views/GolfModeView.swift`
- `HTG/UIComponents/GolfMode/YardageBookPageView.swift`
- `HTG/UIComponents/GolfMode/PageTitleView.swift`
- `HTG/UIComponents/GolfMode/YardageDisplayView.swift`
- `HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift`
- `HTG/UIComponents/GolfMode/YardageLadderView.swift`
- `HTG/UIComponents/GolfMode/MantraView.swift`
- `HTG/UIComponents/GolfMode/PreShotRoutineView.swift`
- `HTG/UIComponents/GolfMode/SwingThoughtsView.swift`
- `HTG/UIComponents/Theme/GTCColor.swift`
- `HTG/UIComponents/Theme/JournalTheme.swift`

## Shared Style Defaults (Current Source of Truth)

### Colors (`GTCColor`)
- Core: `primary`, `secondary`, `background`, `surface`, `border`, `accent`, `text`, `warning`, `swipe`.
- Derived: `ladderSelectionFill`, `ladderSameClubMarker`, `ladderDefaultMarker`, `ladderDefaultText`, `ladderSeparatorSlash`, `ladderTickMinorFill`, `routineSupportingText`, `mantraSupportingText`, `rowHighlight`.

### Typography (`JournalTheme`)
- Reusable font presets: `yardageFont`, `clubNameFont`, `shotTypeFont`, `ladderFont`.
- Generic helpers: `handwritten(size:)`, `handwrittenBold(size:)`, `blockFont(size:)`.

---

## Wireframe Boxes

### 1) Golf Mode Root Container
- **Box Name:** Golf Mode host state container.
- **Base settings:** Full-screen group that switches between loading, empty, and populated content; no explicit background color on container.
- **Placement:** Tab root content (`GolfModeView`).
- **Interaction/clickability:** State-driven only; child views own interactions.
- **Subcomponents:**
  - Loading box: `ProgressView`, full-screen frame.
  - Empty box: icon (`bag`) + title + helper copy with vertical spacing `20`.
- **Dependencies:** Depends on `GolfModeViewModel` load state and `clubs.isEmpty`.
- **Style source tags:** `GTCColor` + `JournalTheme`.
- **Reuse tags:** `state-root`, `empty-state-pattern`.

### 2) Page Layout Shell
- **Box Name:** Yardage book page scaffold.
- **Base settings:** `ScrollView` + left-aligned `VStack(spacing: 14)`, horizontal padding `20`, bottom padding `20`, top title inset `8`.
- **Placement:** Primary full-page content body.
- **Interaction/clickability:** Not directly clickable; hosts tappable sections.
- **Subcomponents (order):**
  - Page title
  - Yardage display
  - Recommendation card (conditional)
  - Yardage ladder
  - Mantra (conditional)
  - Pre-shot routine and swing thoughts side-by-side row (conditional)
- **Dependencies:** Uses `displayedClubShot`, `showResetIndicator`, `showMantra`, `showPreShotRoutine`, and `matchingSwingThoughts` to include/exclude sections.
- **Style source tags:** Mostly layout constants inline.
- **Reuse tags:** `page-rhythm`, `section-order`.

### 3) Title Box (`Decide the Shot!`)
- **Box Name:** Golf page title.
- **Base settings:** No container chrome; text-only element.
- **Placement:** First visual section at top of page shell.
- **Interaction/clickability:** None.
- **Subcomponents:**
  - Text content: `"Decide the Shot!"`
  - Font: `.system(size: 26, weight: .semibold, design: .serif)` (inline, not `JournalTheme`).
  - Text color: `GTCColor.primary`.
- **Dependencies:** None.
- **Style source tags:** Inline font + `GTCColor`.
- **Reuse tags:** `display-title`, `needs-typography-tokenization`.

### 4) Yardage Display Box
- **Box Name:** Editable target yardage display.
- **Base settings:** Left-aligned stack with row-based composition; no outer card.
- **Placement:** Under title in page shell.
- **Interaction/clickability:** Tapping yardage number opens sheet editor; minus/plus stepper buttons update by 1 with hard clamps (50-400).
- **Subcomponents:**
  - Primary yardage value button:
    - Font: `JournalTheme.yardageFont`
    - Color: `GTCColor.primary`
  - Unit label (`yards`): system `14`, `GTCColor.secondary`
  - Stepper controls:
    - 32x32 rounded rectangle (`cornerRadius: 8`)
    - Fill `GTCColor.surface`
    - Border `GTCColor.border` (1pt)
    - Icon color `GTCColor.primary`
  - Edit sheet:
    - Large text field (`JournalTheme.yardageFont`) and `Go` button
    - Save action tint `GTCColor.warning`
    - Sheet height detent `320`
- **Dependencies:** Binds to `targetYardage`; sheet commit clamps value.
- **Style source tags:** `JournalTheme` + `GTCColor` + inline dimensions.
- **Reuse tags:** `primary-metric`, `number-entry-sheet`, `micro-control-card`.

### 5) Recommendation Card Box
- **Box Name:** Shot info header card.
- **Base settings:** Rounded card (`cornerRadius: 14`) with dual treatment:
  - Fill `GTCColor.secondary.opacity(0.08)`
  - Border stroke `GTCColor.primary` (1.5pt)
  - Inner padding `vertical 10`, `horizontal 12`
- **Placement:** Between yardage display and ladder; conditional on `displayedClubShot`.
- **Interaction/clickability:** Entire card taps to open club selector sheet.
- **Subcomponents:**
  - Header row:
    - Recommended pill when recommendation active (capsule stroke in `GTCColor.primary`)
    - Reset icon button when not active (`arrow.counterclockwise` in circular outlined chip)
  - Main row:
    - Club name: serif 28 semibold, `GTCColor.primary`
    - Carry text: serif 18 regular, `GTCColor.text`
  - Shot-type chip:
    - 11 medium text, `GTCColor.secondary`
    - Capsule fill `GTCColor.secondary.opacity(0.08)`
- **Dependencies:** `displayedClubShot` + `showResetIndicator` + optional `onReset`.
- **Style source tags:** `GTCColor` + inline typography.
- **Reuse tags:** `recommendation-card`, `status-pill`, `action-chip`.

### 6) Yardage Ladder Box
- **Box Name:** Carry ladder horizontal chart.
- **Base settings:** Card container with `cornerRadius: 14`, fill `GTCColor.surface`, padding `vertical 10`, `horizontal 8`.
- **Placement:** Middle-right visual emphasis section, below recommendation card.
- **Interaction/clickability:** Bars and labels are independently tappable; selection callback drives club/shot recommendation.
- **Subcomponents:**
  - Horizontal `ScrollView` with dynamic per-column width.
  - Vertical bars:
    - Width: selected 10, default 8
    - Height: normalized from min/max range, min height 18
    - Color: selected `GTCColor.primary`, default `GTCColor.secondary.opacity(0.35)`
  - Target indicator:
    - Dashed vertical line centered on target column
    - Color `GTCColor.accent`, stroke width 1.5, dash `[4, 4]`
  - Labels:
    - Club+shot label (size 9, selected semibold)
    - Carry distance label (size 9, semibold when target)
- **Dependencies:** Uses `targetYardage`, grouped ladder entries, and select callback; auto-centers nearest/target entry on appear and on changes.
- **Style source tags:** `GTCColor` + inline metrics and typography.
- **Reuse tags:** `selectable-data-ladder`, `target-indicator-pattern`.

### 7) Mantra Box
- **Box Name:** Mantra text section.
- **Base settings:** Left-aligned content stack, spacing `6`; no outer border by default.
- **Placement:** Below ladder (conditional).
- **Interaction/clickability:** Read-only.
- **Subcomponents:**
  - Eyebrow label:
    - Text `"Mantra"` uppercased
    - Font size 12 semibold
    - Color `GTCColor.secondary`
  - Quote body:
    - Serif 18 italic
    - Color `GTCColor.primary`
    - Inner padding `vertical 6`, `horizontal 10`
- **Dependencies:** Rendered when `showMantra` is true and uses `mantraText`.
- **Style source tags:** `GTCColor` + inline typography.
- **Reuse tags:** `eyebrow-heading`, `supporting-copy-block`.

### 8) Pre-Shot Routine Box
- **Box Name:** Ordered routine checklist section.
- **Base settings:** Left-aligned content stack, spacing `6`; no outer border by default.
- **Placement:** Lower row, left side (conditional).
- **Interaction/clickability:** Read-only list.
- **Subcomponents:**
  - Eyebrow label:
    - `"Pre-Shot Routine"` uppercased
    - Font size 12 semibold, color `GTCColor.secondary`
  - Routine rows:
    - Number badge: 18x18 with dashed circular border (`GTCColor.border`, dash `[3, 2]`)
    - Number text: 11 medium, `GTCColor.secondary`
    - Item text: 14 regular, `GTCColor.text`
    - Row spacing `8`
- **Dependencies:** Uses sorted `routineItems` by `sortOrder`.
- **Style source tags:** `GTCColor` + inline typography/layout.
- **Reuse tags:** `numbered-steps`, `dashed-badge-pattern`.

### 9) Swing Thoughts Box
- **Box Name:** Bullet list of context-matched thoughts.
- **Base settings:** Left-aligned content stack, spacing `6`; no outer border by default.
- **Placement:** Lower row, right side (conditional).
- **Interaction/clickability:** Read-only list.
- **Subcomponents:**
  - Eyebrow label:
    - `"Swing Thoughts"` uppercased
    - Font size 12 semibold, `GTCColor.secondary`
  - Thought rows:
    - Accent bullet (`•`) in `GTCColor.accent`
    - Body text size 13 regular in `GTCColor.text`
    - Row spacing `4`
- **Dependencies:** Uses `matchingSwingThoughts`; renders only when list is non-empty.
- **Style source tags:** `GTCColor` + inline typography/layout.
- **Reuse tags:** `accent-bullet-list`, `contextual-notes`.

### 10) Club Selector Sheet (Interaction-Linked Box)
- **Box Name:** Club/shot selector modal for recommendation override.
- **Base settings:** Presented as a sheet from `YardageBookPageView` when recommendation card is tapped.
- **Placement:** Modal overlay.
- **Interaction/clickability:** Selecting club/shot triggers `onSelectClubShot`, updates recommendation, yardage display, and ladder highlight.
- **Subcomponents:** Not fully mapped in this doc; this item is included to preserve the interaction dependency chain for wireframe behavior.
- **Dependencies:** `displayedClubShot`, `clubs`, `allShotTypeNames`, and selection callback from `GolfModeViewModel`.
- **Style source tags:** Mixed (`GTCColor`, `JournalTheme`, and local view styling).
- **Reuse tags:** `modal-selector`, `cross-box-state-sync`.

---

## Cross-Box Interaction Dependencies
- Ladder selection (`onSelectEntry`) and selector sheet selection (`onSelectClubShot`) both call the same view model selection path.
- Selection updates these boxes in lockstep:
  - Recommendation card content and reset affordance
  - Yardage numeric display
  - Swing thoughts list
  - Ladder selected/target visuals
- Reset action restores recommendation state via view model and collapses override styling.

## Tokenization and Reuse Notes
- Strongly reusable visual patterns:
  - Eyebrow headers (12 semibold + `GTCColor.secondary` + uppercase)
  - Rounded micro-controls (`surface` fill + `border` stroke + `primary` icon/text)
  - Recommendation card shell (`secondary` tint + `primary` stroke)
  - Accent bullet / dashed badge motifs for supporting information.
- Remaining inline style debt (cleanup candidates):
  - Some explicit `.system(...)` fonts should become named typography defaults if reused across features.
  - Hardcoded spacings/radii should move into shared layout tokens for cross-mode parity.
