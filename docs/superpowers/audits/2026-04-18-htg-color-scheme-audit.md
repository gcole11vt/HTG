# HTG Color Scheme Audit (GTC alignment)

**Date:** 2026-04-18  
**Canonical palette (reference):** [`gtc_colors.py`](../../../gtc_colors.py) — `COLORS` dict  
**Swift theme today:** [`HTG/UIComponents/Theme/JournalTheme.swift`](../../../HTG/UIComponents/Theme/JournalTheme.swift)

---

## 1. Token mapping matrix (`gtc_colors.py` → Swift)

| Python key | Hex | Semantic role | Recommended Swift token (static `Color` or nested enum) |
|------------|-----|-----------------|------------------------------------------------------------|
| `primary` | `#29443A` | Brand / primary UI (dark forest) | `GTCColor.primary` |
| `secondary` | `#7E9286` | Muted sage, secondary chrome | `GTCColor.secondary` |
| `background` | `#F7F7F2` | App / screen background | `GTCColor.background` |
| `surface` | `#FFFFFF` | Cards, sheets, elevated surfaces | `GTCColor.surface` |
| `border` | `#CDD4CE` | Dividers, strokes, borders | `GTCColor.border` |
| `accent` | `#705C49` | Warm brown accent | `GTCColor.accent` |
| `text` | `#2C342F` | Primary body text | `GTCColor.text` |
| `warning` | `#92400E` | Warning / caution | `GTCColor.warning` |
| *(approved §1.1; add to Python when syncing)* | `#C97B2F` | Swipe / archive tint | `GTCColor.swipe` |

**Note:** Current `JournalTheme` uses a different visual language (e.g. `inkBlue`, `redMarker`, `targetGreen`). Aligning with GTC means either **replacing** those RGB values with GTC hex-derived colors, **aliasing** old names to new tokens, or **deprecating** journal names in favor of `GTCColor` + semantic roles.

### 1.1 System / ad hoc colors → approved GTC map

These are the **authoritative replacements** for Apple system colors and ad-hoc literals found in `ClubListView`, `RangeModeView`, and `ClubSelectorSheetView`. Implement Swift tokens with these hex values (add **`swipe`** to `gtc_colors.py` when you want Python and Swift to stay in sync — it is not in `COLORS` today).

| Current (Swift / system) | Closest GTC role | Hex | Notes |
|--------------------------|------------------|-----|--------|
| Orange (e.g. `.tint(.orange)`) | **Swipe** | `#C97B2F` | New palette token for swipe/archive affordance. |
| Green (e.g. `.tint(.green)`, `Color.green`, `.green`) | **Primary** | `#29443A` | Matches `gtc_colors.py` `primary`. |
| Red (e.g. `.foregroundStyle(.red)`, `Color.red`, `.red`) | **Warning** | `#92400E` | Matches `gtc_colors.py` `warning`. |
| Gray (e.g. `.foregroundStyle(.gray)`) | **Border** | `#CDD4CE` | Matches `gtc_colors.py` `border`. |
| White (e.g. `.foregroundStyle(.white)`) | **Surface** | `#FFFFFF` | Matches `gtc_colors.py` `surface`. |

**Migration implications**

- **Delta badge** (`ClubListView`): replace `Color.green.opacity(0.2)` / `Color.red.opacity(0.2)` with **`primary` / `warning`** at controlled opacity (or dedicated derived tokens), not system green/red.
- **`.primary` / `.secondary`** (Range / Profile / Clubs): unchanged by this table — still a **P4 policy** choice (keep system semantics vs map to `text` / `secondary`).

---

## 2. Color definition inventory

| Location | Type | Contents | Classification |
|----------|------|----------|----------------|
| [`HTG/UIComponents/Theme/JournalTheme.swift`](../../../HTG/UIComponents/Theme/JournalTheme.swift) | Swift `Color(red:green:blue:)` statics | `leatherBrown`, `leatherDark`, `agedPaper`, `paperDark`, `inkBlue`, `redMarker`, `mutedGray`, `goldEmboss`, `targetGreen` + font helpers | **Current de facto Swift palette** — not derived from `gtc_colors.py`. |
| [`HTG/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`](../../../HTG/Resources/Assets.xcassets/AccentColor.colorset/Contents.json) | Asset colorset | Universal entry with **no** explicit RGB/hex (Xcode default / system-driven) | **Non-tokenized** — does not encode GTC or JournalTheme. |
| [`gtc_colors.py`](../../../gtc_colors.py) | Python `COLORS` dict | Full GTC palette | **Intended canonical reference** for workflows; **not referenced** by Swift in this repo. |

**Unused `JournalTheme` color tokens (defined only in `JournalTheme.swift`, no other Swift references):**

- `leatherBrown`, `leatherDark`, `agedPaper`, `goldEmboss`

**Likely legacy** after removed leather/paper UI (per prior deletions in git history).

**Additional colorsets:** Only `AccentColor.colorset` exists under `Assets.xcassets`; no per-token `.colorset` files.

---

## 3. Color usage inventory

### 3.1 Views using `JournalTheme` (standardized path)

| File | Usage summary |
|------|----------------|
| [`HTG/UIComponents/GolfMode/ClubShotRowView.swift`](../../../HTG/UIComponents/GolfMode/ClubShotRowView.swift) | `targetGreen`/`redMarker` differential; `inkBlue`, `mutedGray`, `paperDark`, `Color.clear` |
| [`HTG/UIComponents/GolfMode/ClubShotBadgeView.swift`](../../../HTG/UIComponents/GolfMode/ClubShotBadgeView.swift) | `inkBlue`, `mutedGray`, `redMarker` stroke |
| [`HTG/UIComponents/GolfMode/LadderClubMarkerView.swift`](../../../HTG/UIComponents/GolfMode/LadderClubMarkerView.swift) | `redMarker`/`inkBlue` + opacity variants |
| [`HTG/UIComponents/GolfMode/GroupedLadderClubMarkerView.swift`](../../../HTG/UIComponents/GolfMode/GroupedLadderClubMarkerView.swift) | Same pattern + `textColor.opacity` |
| [`HTG/UIComponents/GolfMode/LadderTickMarkView.swift`](../../../HTG/UIComponents/GolfMode/LadderTickMarkView.swift) | `targetGreen`, `inkBlue.opacity(0.5)` |
| [`HTG/UIComponents/GolfMode/YardageDisplayView.swift`](../../../HTG/UIComponents/GolfMode/YardageDisplayView.swift) | `inkBlue`, `tint(redMarker)` |
| [`HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift`](../../../HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift) | `inkBlue`, `mutedGray` |
| [`HTG/UIComponents/GolfMode/PageTitleView.swift`](../../../HTG/UIComponents/GolfMode/PageTitleView.swift) | `inkBlue` |
| [`HTG/UIComponents/GolfMode/PreShotRoutineView.swift`](../../../HTG/UIComponents/GolfMode/PreShotRoutineView.swift) | `mutedGray`, `inkBlue.opacity(0.7)` |
| [`HTG/UIComponents/GolfMode/SwingThoughtsView.swift`](../../../HTG/UIComponents/GolfMode/SwingThoughtsView.swift) | `mutedGray`, `inkBlue.opacity(0.7)` |
| [`HTG/UIComponents/GolfMode/MantraView.swift`](../../../HTG/UIComponents/GolfMode/MantraView.swift) | `inkBlue.opacity(0.8)` |
| [`HTG/UIComponents/GolfMode/AllShotsOverviewPanelView.swift`](../../../HTG/UIComponents/GolfMode/AllShotsOverviewPanelView.swift) | `mutedGray` |
| [`HTG/UIComponents/GolfMode/ClubDetailPanelView.swift`](../../../HTG/UIComponents/GolfMode/ClubDetailPanelView.swift) | `tint(inkBlue)` |
| [`HTG/UIComponents/GolfMode/ResetIndicatorView.swift`](../../../HTG/UIComponents/GolfMode/ResetIndicatorView.swift) | `mutedGray` |
| [`HTG/Features/GolfMode/Views/GolfModeView.swift`](../../../HTG/Features/GolfMode/Views/GolfModeView.swift) | `inkBlue`, `mutedGray` |
| [`HTG/Features/GolfMode/Views/ClubSelectorSheetView.swift`](../../../HTG/Features/GolfMode/Views/ClubSelectorSheetView.swift) | `mutedGray`, `inkBlue` fills + **`.white` label** → map to **surface** `#FFFFFF` per §1.1 |

### 3.2 System semantic colors (Apple `ShapeStyle`, not app tokens)

| File | Pattern |
|------|---------|
| [`HTG/Features/Profile/Views/ProfileView.swift`](../../../HTG/Features/Profile/Views/ProfileView.swift) | `.foregroundStyle(.secondary)` (multiple) |
| [`HTG/Features/ClubManagement/Views/ClubListView.swift`](../../../HTG/Features/ClubManagement/Views/ClubListView.swift) | `.secondary` (many rows/labels) |
| [`HTG/Features/RangeMode/Views/RangeModeView.swift`](../../../HTG/Features/RangeMode/Views/RangeModeView.swift) | `.secondary`, `.primary` on large stat value |

### 3.3 No explicit color API

| File | Notes |
|------|--------|
| [`HTG/App/ContentView.swift`](../../../HTG/App/ContentView.swift) | `TabView` only — system tab bar styling |
| [`HTG/App/HTGApp.swift`](../../../HTG/App/HTGApp.swift) | No color modifiers |
| [`HTG/UIComponents/GolfMode/YardageBookPageView.swift`](../../../HTG/UIComponents/GolfMode/YardageBookPageView.swift), [`YardageLadderView.swift`](../../../HTG/UIComponents/GolfMode/YardageLadderView.swift) | Compose child views; no direct color literals |

### 3.4 Non-UI Swift

Services, models, view models under `HTG/Core/` — **no** color styling APIs found in audit grep pass.

---

## 4. Non-standard usage report

**Definition:** Color choices that bypass a single GTC-aligned token layer (`gtc_colors.py` / future `GTCColor`), or that mix **system** palette (`.green`, `.red`) with **JournalTheme** without a documented exception.

**Approved replacement map for those literals:** see **§1.1** (Orange→Swipe `#C97B2F`, Green→Primary `#29443A`, Red→Warning `#92400E`, Gray→Border `#CDD4CE`, White→Surface `#FFFFFF`).

### 4.1 High priority — system literals / ad-hoc fills (each tied to §1.1)

| File | Area | Current | Replace with (hex / role) |
|------|------|---------|---------------------------|
| [`ClubListView.swift`](../../../HTG/Features/ClubManagement/Views/ClubListView.swift) | Swipe archive tint | `.tint(.orange)` | **Swipe** `#C97B2F` |
| [`ClubListView.swift`](../../../HTG/Features/ClubManagement/Views/ClubListView.swift) | Swipe restore / range tints | `.tint(.green)` (multiple) | **Primary** `#29443A` |
| [`ClubListView.swift`](../../../HTG/Features/ClubManagement/Views/ClubListView.swift) | Nickname hint | `.foregroundStyle(.gray)` | **Border** `#CDD4CE` |
| [`ClubListView.swift`](../../../HTG/Features/ClubManagement/Views/ClubListView.swift) | Delta badge background | `Color.green.opacity(0.2)` / `Color.red.opacity(0.2)` | **Primary** / **Warning** at ~0.2 opacity (or named derived tokens) |
| [`ClubListView.swift`](../../../HTG/Features/ClubManagement/Views/ClubListView.swift) | Delta badge text | `.foregroundStyle(.green / .red)` | **Primary** `#29443A` / **Warning** `#92400E` |
| [`RangeModeView.swift`](../../../HTG/Features/RangeMode/Views/RangeModeView.swift) | Save buttons | `.tint(.green)` (×2) | **Primary** `#29443A` |
| [`RangeModeView.swift`](../../../HTG/Features/RangeMode/Views/RangeModeView.swift) | Trash icon | `.foregroundStyle(.red)` | **Warning** `#92400E` |
| [`RangeModeView.swift`](../../../HTG/Features/RangeMode/Views/RangeModeView.swift) | “Current” stat | `statItem(..., color: .green)` | **Primary** `#29443A` |
| [`ClubSelectorSheetView.swift`](../../../HTG/Features/GolfMode/Views/ClubSelectorSheetView.swift) | “Select” on filled capsule | `.foregroundStyle(.white)` | **Surface** `#FFFFFF` |

### 4.2 Medium priority — repeated opacity “micro-tokens”

Same base color (`JournalTheme.inkBlue`, `redMarker`) with **magic** opacity values scattered across views:

| Opacity | Files |
|---------|--------|
| `0.1` | `LadderClubMarkerView`, `GroupedLadderClubMarkerView` (red fill) |
| `0.5` | `LadderClubMarkerView`, `GroupedLadderClubMarkerView`, `LadderTickMarkView`, `GroupedLadderClubMarkerView` (`textColor`) |
| `0.6` / `0.8` | Marker fill logic in ladder marker views |
| `0.7` | `PreShotRoutineView`, `SwingThoughtsView` |
| `0.8` | `MantraView` |

These are **centralized base hues** but **decentralized luminance** — hard to align globally with GTC without named derived tokens (e.g. `textSecondary`, `markerFillMuted`).

### 4.3 Low priority / acceptable by policy

- **`.primary` / `.secondary`** in Range/Profile/Clubs lists — acceptable if product policy is “use system semantic text for settings-style screens.”
- **`Color.clear`** — not a brand color.
- **`ResetIndicatorView`**: `.opacity(isPressed ? 0.5 : 1.0)` — view alpha, not palette drift.

### 4.4 Gaps vs GTC palette

- **`gtc_colors.py`** defines `background`, `surface`, `border`, `text`, `warning`, etc. — **none** of these appear as Swift tokens today (except indirectly via planned migration).
- **Swipe** `#C97B2F` is **approved in §1.1** but **not yet** in `gtc_colors.py`; add a `swipe` (or `swipe_archive`) key when syncing Python and Swift.
- **`JournalTheme`** provides no direct mapping to GTC `primary` / `accent` / `text`; `inkBlue` is a different hue family than GTC `text` / `primary`.

---

## 5. Prioritized alignment backlog

### P0 — Establish Swift source of truth from GTC

1. Add a Swift token type (e.g. `enum GTCColor` or extend theme) with **RGB/hex values matching** `gtc_colors.py` (single place in Swift; optionally generate from Python in CI later).
2. Decide **migration strategy** for `JournalTheme`:
   - **Option A:** Replace RGB values inside existing names (`inkBlue` → GTC `text`, etc.) — fastest but naming stays misleading.
   - **Option B:** Introduce `GTCColor.*` and migrate call sites — clearest.
3. Add **Asset colorsets** for each token if you want Interface Builder / dark-mode variants later; until then, Swift static `Color` is enough.

### P1 — Replace high-drift system literals (per §1.1)

| Order | File | Change |
|-------|------|--------|
| 1 | `ClubListView.swift` | `.tint(.orange)` → token **swipe** `#C97B2F`. `.tint(.green)` → **primary** `#29443A`. `.gray` → **border** `#CDD4CE`. Delta foreground/background → **primary** / **warning** `#92400E` (with opacity on fills as needed). |
| 2 | `RangeModeView.swift` | `.tint(.green)` and `statItem(..., .green)` → **primary** `#29443A`. `.red` on trash → **warning** `#92400E`. |
| 3 | `ClubSelectorSheetView.swift` | `.white` on “Select” label → **surface** `#FFFFFF` (per map; ensure contrast vs fill once fills are also GTC-aligned). |

### P2 — Collapse opacity variants

- Extract shared derived colors from ladder + routine views into `JournalTheme` (or `GTCColor`) as named statics, e.g. `inkBlueMuted`, `redMarkerSelectionFill`, to remove duplicated `0.5`/`0.6`/`0.7`/`0.8` literals.

### P3 — Cleanup and assets

- Remove or document **unused** `JournalTheme` colors: `leatherBrown`, `leatherDark`, `agedPaper`, `goldEmboss`.
- Set **`AccentColor`** in asset catalog to `GTCColor.primary` (or `accent`) if you rely on system `.tint` for controls without explicit `.tint()`.

### P4 — Policy decision (documentation)

- Explicitly state whether **Profile / Range / Clubs** lists keep **`.secondary` / `.primary`** or switch to **`GTCColor.text`** with opacity variants for full GTC lock-in.

---

## 6. Acceptance criteria (alignment done when)

- Every **non-system** product color in `HTG/` resolves through **one** Swift token layer whose values **match** `gtc_colors.py` (or documented delta).
- **Test-mode** UI (if any) uses the **four** test-mode tokens from Python.
- **Exceptions** (system `.primary`, etc.) are listed in `CLAUDE.md` or theme README with rationale.
- No remaining **`.green` / `.red` / `.orange` / `.gray` / `.white`** for product chrome: each maps to a named token per **§1.1** (**swipe**, **primary**, **warning**, **border**, **surface**).

---

## 7. Verification commands (for follow-up implementation)

```bash
# Swift color literal definitions (should shrink to token file(s) only)
rg 'Color\(red:' HTG --glob '*.swift'

# Ad-hoc system palette (should trend to zero after migration)
rg '\.tint\(\.(green|orange|red)|Color\.(green|red)|foregroundStyle\(\.(green|red|gray|white)' HTG --glob '*.swift'

# JournalTheme drift check
rg 'JournalTheme\.' HTG --glob '*.swift'
```

---

*End of audit deliverable.*
