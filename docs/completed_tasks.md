## Completed Tasks

---

**Task name:**  Range Mode - Voice input crash/freeze fix and yardage read-back
**Priority:**  P1
**Status:**  Complete
**What it is:**  Tapping the mic button in Range Mode crashed (mic permission was never requested, so the audio tap got an invalid format), then froze (permission requests and audio engine startup blocked the main thread). Fixed by requesting both speech + mic permissions off the main thread and moving audio session/engine startup to a background task. Also fixed the yardage read-back, which was being cut off before it played (now waits for the synthesizer's didFinish callback), and audio routing so it plays at normal volume and through Bluetooth headphones.

---

**Task name:**  Range Mode - Carry Distance Save
**Priority:**  P1
**Status:**  Complete
**What it is:**  In Range Mode, when the user goes to save their session, the median populates in the pop-up, but the user must change the number to save because Save isn't functional until something is altered. The save button should automatically work as long as any number is in the field.

---

**Task name:**  Utilize wireframe from Claude design - Golf Mode
**Priority:**  P1 
**Status:** Complete
**What it is:**  Attempting to build in Cursor

---

**Task name:**  Secondary Colors on non-utilized icons on tab dock
**Priority:** P2
**Status:** Complete
**What it is:**  Change the color of the icons in the dock which aren't being utilized in the view to be GTC_Colors secondary

---

**Task name:**  Remove "About Handicap" from the profile
**Priority:** P3  
**Status:** Complete  
**What it is:**  In the Profile section, at the bottom there is a section "About Handicap". It should be removed entirely

---

**Task name:**  Utilize wireframe from Claude design - Range Mode
**Priority:**  P1 
**Status:** Complete
**What it is:**  Refactor Range Mode to match Golf Mode visual style using a documentation-first migration path. Completed via shared style layer: `GTCCardStyle.swift` (card shells, `GTCSectionEyebrow`, `GTCMetaChip`, prominent button) + `JournalTheme` tokens (eyebrow unified to Golf's 12-semibold, `cardTitleFont`, `chipLabelFont`, `metricLabelFont`, input widths, sheet detent). RangeModeView contains no inline card shells or typography-size literals (icon sizes excepted).

---

**Task name:**  Utilize wireframe from Claude design - Club Mode
**Priority:**  P1 
**Status:** Complete
**What it is:**  Refactor Club Management Mode to match Golf Mode visual style using a documentation-first migration path. Club card styles now delegate to the shared `gtcCard` shells; eyebrows/buttons use the shared `GTCSectionEyebrow`/`gtcProminentActionButtonStyle`. Cross-feature theme tokens renamed to drop the misleading `range` prefix.

---

**Task name:**  Printable yardage sheets
**Priority:** P2
**Status:** Complete
**What it is:**  Tournament-legal printed yardages. A printer icon on the Clubs tab opens a sheet with a live US Letter preview and two layouts: By Club (each club with its shot types and yardages, longest club first) and By Yardage (one flat list sorted longest to shortest). Print goes through AirPrint; Share exports the PDF. Archived clubs/shot types and un-dialed (0-yard) shot types are excluded. Data building lives in `YardageSheetBuilder` (unit tested), PDF rendering in `YardageSheetPDFRenderer`, UI in `YardageSheetView`.

---

**Task name:**  Range Mode continuous voice reliability
**Priority:** P1
**Status:** Complete
**What it is:**  Continuous voice input silently died after ~60 seconds because Apple's server-based speech recognition kills every task at about a minute and the app never restarted it. Fixed: recognition now restarts automatically whenever a task dies mid-session, uses on-device recognition when available (no time limit, works offline), gives up cleanly with the mic icon reflecting reality if recognition fails repeatedly, and speaks "<distance>. Next shot." after logging each shot.

---


**Task name:**  Supabase sync foundation
**Priority:** P1
**Status:** Complete
**What it is:**  Cross-device sync with Supabase (chosen over CloudKit). SwiftData stays the offline source of truth; `SyncService.syncAll()` runs a per-entity push/pull cycle (parents before children) with pure last-write-wins merge logic in `SyncEngine` (unit tested). All 8 synced models carry `updatedAt`, every data-service mutation stamps it, and hard-deletes record a `SyncTombstone` that propagates through a `sync_deletions` table. Auth is Sign in with Apple exchanged for a Supabase session (`SupabaseAuthService`); Profile tab gained an Account & Sync card (sign in, sync now, status, sign out). supabase-swift SDK added via SPM. Remote side is fully specified in `docs/supabase/schema.sql` (tables + RLS) with setup steps in `docs/supabase/setup.md` — the app runs offline-only until `SupabaseConfig` is filled in with a real project URL/anon key.

---
**Task name:**  Sync & Profile cleanup batch (5 items)
**Priority:** P1
**Status:** Complete
**What it is:**  (1) Golf Mode gained a refresh button next to the yardage +/- steppers that reloads the bag from the store and resets to the recommendation, so bag edits show up without switching tabs. (2) Fixed duplicate clubs after reinstall: `loadDefaultClubs` now records the seeded bag in UserDefaults, and the first sync discards untouched seeded clubs when the remote already has a real bag (modified seeds are kept). (3) Restyled the "Add Swing Thought" and "Initial Bag Set Up" buttons from oversized prominent buttons into handwritten-font accent-card rows matching the rest of the Profile page. (4) Pre-shot routine steps now have visible pencil (edit via alert) and trash (delete) controls; swipe-to-delete and drag-to-reorder still work. (5) Fixed name/handicap "not syncing": a fresh install auto-created an empty profile under a new UUID, so the pulled remote profile became a second row and the UI could show the empty one. First sync now discards pristine local profiles when the remote has one, every sync consolidates duplicate profiles (keeping the personalized one, tombstoning extras and their children so remotes converge), `getOrCreateProfile` prefers the personalized profile, and the Profile page reloads after sign-in/Sync Now. 7 new unit tests.

---
**Task name:**  Golf Mode: Settings panel and View option
**Priority:** P1
**Status:** Complete
**What it is:**  Pre-Shot Routine, Mantra and Swing Thoughts moved off the Profile page into a new pushed "Golf Mode" settings screen (`GolfModeSettingsView`, with the Add Swing Thought sheet extracted to `AddSwingThoughtSheetView`). The panel gained a View option (Ladder | Text) backed by the reusable `DistanceViewStyle` enum, stored on `UserProfile` (`golfModeViewStyleRawValue`, default Text) and synced as optional `golf_mode_view_style`. Golf Mode still renders the Ladder until the Text view task ships. Pushes tolerate a remote without the new column (PGRST204 retry via `SyncPayloadStripper`); the SQL is committed in `docs/supabase/migrations/` but not applied, so the setting is device-local until it is.

---

**Task name:**  Golf Mode: Text view
**Priority:** P1
**Status:** Complete
**What it is:**  Golf Mode now honors the View setting (Text is the default). The Text page shows a fixed header (title, target yardage, shot card) above a scrolling text ladder of the whole bag in the same order as Clubs > Print > By Yardage (distance, club, shot type), with Mantra, Pre-Shot Routine and Swing Thoughts in a fixed right column. The row nearest the target is bold, the selected/recommended row is tinted, and a dashed marker shows the target between rows when there is no exact match. Tapping a row selects that shot; changing the yardage, refresh and returning to the tab re-centre the list. Ladder math lives in the unit-agnostic `DistanceTextLadderService` (yards now, feet reusable for Putting mode); the shared header was extracted to `GolfModeShotHeaderView`. The "coming soon" note was removed from Golf Mode settings. 20 new unit tests. Not yet verified visually in the simulator.

---

---

**Task name:**  Golf Mode: Yardage entry is one tap
**Priority:** P1
**Status:** Complete
**What it is:**  The big target yardage number in the Golf Mode header (shared by the Ladder and Text pages) is now an inline text field. One tap raises a blank number pad (the old value shows as a faint hint) and the +/- /refresh buttons swap to Cancel and Go; no more sheet or second tap. Go is enabled only for 50-400 yards, with a range caption that turns to a warning at three out-of-range digits. Behavior change: out-of-range entries are now rejected instead of silently clamped. Losing focus (tab switch, backgrounding) discards the entry. Validation lives in `YardageEntryValidationService` (range shared with `GolfModeViewModel`, reusable for Putting). 14 new unit tests. Not yet verified visually in the simulator.

---

---

**Task name:**  Golf Mode: Yardage microphone button
**Priority:** P1
**Status:** Complete
**What it is:**  A mic button sits immediately left of the Reset (refresh) button in the Golf Mode yardage row (Ladder and Text pages). Tap it, say a yardage ("150", "one fifty", "one hundred fifty yards", "two twenty five") and it fills in the target after a short pause so later words are not cut off; tap again to stop. Only 50-400 is accepted (via `YardageEntryValidationService`); it times out after 8 seconds of nothing usable and shows a status line for denied permission or start failure. It reuses Range Mode's `SpeechRecognitionService` through `SpeechRecognitionYardageListener` plus an additive, default-nil `onTranscriptUpdate` callback, so Range Mode is unchanged. Parsing is in `YardageSpokenParser`, state in `YardageVoiceEntryViewModel` (start guard, cancel-during-start handling). Listening is cancelled on tab change/backgrounding. Unit-tested; not yet verified on a device with a real microphone.

---

**Task name:**  Putting mode
**Priority:** P1
**Status:** Complete (Align Speed calibration wizard still to come)
**What it is:**  New fifth tab, Putting (Golf, Putting, Range, Clubs, Profile). Enter the putt distance in feet (same one-tap number-pad entry as Golf Mode, 1-99 ft) and see a suggested stroke from your calibrated speeds: "Position 3", or "Position 2½" when the distance falls midway between two positions, with the feet each position rolls. The curve is shown as a Ladder or Text view and follows Golf Mode's View setting (footer "Also used in Putting." added). Without a calibration the tab shows an "Align your speed" prompt; the Align Speed button is present but disabled until the wizard ships. Calibrations are stored on the device only (new `PuttingCalibration` models, not synced). Math lives in `PuttingSpeedCurveService` (mean, monotonic smoothing, half-position snapping). The yardage entry field was generalized with `DistanceEntryConfiguration`; Golf Mode behaves as before. About 50 new unit tests. Not yet verified visually in the simulator.
