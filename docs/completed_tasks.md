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
