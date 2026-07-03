# Session Handoff — 2026-07-03

Context doc for continuing HTG work in a fresh session. Read this alongside `CLAUDE.md`, `docs/backlog.md`, and `docs/completed_tasks.md`.

## Where things stand

The app is visually unified and functionally solid. All four tabs (Golf, Range, Clubs, Profile) now share one style system derived from Golf Mode (the canonical reference, per `docs/wireframes/GolfModeWireFrame.md`). Build is clean, all unit tests pass (`TDD Runner` command in CLAUDE.md).

### Completed this session (all committed on `main`, not pushed)

| Commit | What |
|---|---|
| `77548d7` | docs: Club wireframe mapping + backlog/completed-tasks tracking |
| `488069b` | fix: continuous voice input survives entire range session |
| `a0a47ea` | fix: About Handicap removed, tab dock unselected tint |
| `e4f97d6` | feat: shared GTC card/eyebrow style layer (`GTCCardStyle.swift`) |
| `d7e37ff` | feat: expandable club rows in Club Mode (read-only, chevron → detail) |
| `d2ae8d1` | feat: printable yardage sheets (By Club / By Yardage, AirPrint + Share PDF) |
| `1211c17` | fix: ladder blends into page bg; target line interpolates to actual yardage |
| `6e0df3a` | fix: Range save-sheet Save button reachable immediately (was under keyboard) |
| `d55fd36` | feat: Club Mode header aligned with Golf/Range; bold primary yardage in dropdown |
| `9825746` | feat: Profile page rethemed to shared GTC style |

`docs/backlog.md` has uncommitted user edits — it is **user-curated**; log finished work in `docs/completed_tasks.md` instead of deleting backlog entries.

## Key architecture facts (non-obvious)

- **Shared style layer**: `HTG/UIComponents/Theme/GTCCardStyle.swift` — `gtcNeutralCard()/gtcAccentCard()/gtcTintedAccentCard()` card shells, `GTCSectionEyebrow`, `GTCMetaChip`, `gtcProminentActionButtonStyle()`. All pages consume these; never compose card/eyebrow styling inline. Typography/layout tokens live in `JournalTheme` (eyebrow = 12 semibold app-wide; `pageTitleFont` serif 26; `cardTitleFont` serif 28). Colors only through `GTCColor` (canonical hexes from `gtc_colors.py`).
- **Xcode project is NOT folder-synced** (`objectVersion = 63`, explicit refs). New files must be registered in `HTG.xcodeproj/project.pbxproj` by hand: PBXBuildFile + PBXFileReference + group children + Sources phase (app and test targets have separate Sources phases). Existing IDs follow a loose `X1000...229F...` pattern — pick any unique ID.
- **Voice input** (`SpeechRecognitionService`): recognition tasks die at ~60s (Apple server cap) or on errors; in continuous mode the service auto-restarts on task death (guarded by `isListening` to skip deliberate stops), prefers on-device recognition, and gives up after 3 rapid consecutive failures (task lived < 2s). Speaks "«distance». Next shot." after each logged shot.
- **Yardage sheets**: pure logic in `YardageSheetBuilder` (11 unit tests), PDF via `YardageSheetPDFRenderer` (ImageRenderer → single US Letter page), UI `YardageSheetView`. Known limitation: no pagination — clips if a bag ever exceeds ~90 print lines.
- **Ladder target line** (`YardageLadderView`): `targetIndicatorOffset` interpolates between bracketing columns; scroll-centering still uses nearest column (`centeredTargetColumnID`) — that's intentional.

## User's working preferences (observed)

- Superpowers/brainstorming ceremony disabled — work directly, no design-doc gates.
- Commits only when asked, **split by feature**, messages in repo's `feat:`/`fix:`/`docs:` style with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` trailer. Commit to `main` directly (repo convention). Never push.
- TDD for service logic (per CLAUDE.md); views verified by build + on-device eyeballing by the user.
- Report findings first when they describe a problem; fix on request.

## Next up (agreed priority)

1. **Supabase sync** — ✅ app-side foundation IMPLEMENTED (2026-07-03, uncommitted). What exists:
   - `HTG/Core/Services/Sync/`: `SyncEngine` (pure LWW merge, 12 unit tests), `SyncRecords` (snake_case DTOs + model mapping), `SyncService` (per-entity push/pull orchestration, 7 tests vs fake store), `SupabaseRemoteStore`/`SyncRemoteStore` protocol, `SupabaseAuthService` (SiWA id-token flow), `SupabaseClientProvider` (**placeholder URL/key — app runs offline-only until filled**).
   - All 8 synced models have `updatedAt` (declaration-default for migration); every service mutation stamps it (17 tests in `SyncTouchTests`); hard-deletes insert `SyncTombstone` rows, cleared after push.
   - Profile tab: Account & Sync card (SignInWithAppleButton, Sync Now, status, Sign Out). `HTG/App/HTG.entitlements` added with applesignin capability.
   - supabase-swift 2.49.0 via SPM (hand-registered in pbxproj: XCRemoteSwiftPackageReference `SP...` IDs).
   - **Remaining (user-side)**: create Supabase project, run `docs/supabase/schema.sql`, configure Apple provider, paste URL/anon key into `SupabaseClientProvider.swift` — steps in `docs/supabase/setup.md`. Then end-to-end test on two devices. No auto-sync triggers yet beyond Profile-tab restore+sync; consider background/foreground sync hooks later.
2. **Golf Mode left-column polish** (P2 backlog) — user deferred ("skip"), not dead: even box distribution, same font size across pre-shot routine / swing thoughts / mantra.
3. **Light-mode background sweep** (P3 backlog) — verify every screen uses `GTCColor.background`.
4. **First Time Set Up flow** (P3 backlog) — full spec with yardage-estimation algorithm lives in `docs/backlog.md`.
5. **Profile wireframe** (P1 backlog) — user said they're building this in Cursor; the Profile retheme (`9825746`) may partially or fully cover it — confirm with user before touching.

## Verification

- Build: `xcodebuild -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator build`
- Tests: destination by name can fail; use UDID instead: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'id=77318A23-A031-4967-A674-1D2BCD4C5952' -only-testing HTGTests`
- SourceKit diagnostics in-session show phantom "Cannot find type" errors across files — index noise, trust `xcodebuild`.
