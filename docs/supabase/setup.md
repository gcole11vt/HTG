# Supabase Sync Setup

One-time setup to turn on cross-device sync. Until this is done the app runs
fully offline and the Profile page shows "Cloud sync isn't set up yet."

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) → New project (free tier is fine).
2. Pick any name (e.g. `htg`) and a strong database password (you won't need it day-to-day).

## 2. Create the tables

1. Dashboard → **SQL Editor** → New query.
2. Paste the entire contents of `docs/supabase/schema.sql` and run it.

## 3. Enable Sign in with Apple

Apple side (developer.apple.com → Certificates, Identifiers & Profiles):

1. Open the App ID `com.htg.HTG` and enable the **Sign in with Apple** capability, then regenerate/re-download provisioning if you manage profiles manually (Xcode automatic signing handles this once the capability is on the App ID).

Supabase side (Dashboard → **Authentication → Sign In / Up → Apple**):

1. Enable the Apple provider.
2. In **Client IDs**, add the app's bundle id: `com.htg.HTG`.
   (No secret key is needed for the native iOS id-token flow.)

## 4. Point the app at your project

1. Dashboard → **Settings → API**: copy the **Project URL** and the **anon public** key.
2. Paste both into `HTG/Core/Services/Sync/SupabaseClientProvider.swift`
   (`SupabaseConfig.projectURL` / `SupabaseConfig.anonKey`).
   The anon key is safe to embed in the app — row-level security restricts
   every row to its owner.

## 5. Use it

Build and run. Profile tab → **Account & Sync** → Sign in with Apple. The
first sync pushes everything local; afterwards each sync exchanges only
changes since the last one (`updated_at` based, last-write-wins, deletes
propagate via the `sync_deletions` table).

## How sync works (for future reference)

- `SyncService.syncAll()` runs one push/pull cycle per entity, parents before
  children (profiles → clubs → shot types → sessions → shots → routine items →
  swing thoughts → settings).
- Conflict resolution is pure logic in `SyncEngine` (unit-tested): newest
  `updatedAt` wins; deletes carry their own timestamp and can be overridden by
  a newer edit.
- Every data-service mutation stamps `updatedAt`; hard-deletes insert a local
  `SyncTombstone` row which is cleared once pushed.
- `lastSyncedAt` is stored per Supabase user in `UserDefaults`, so switching
  accounts triggers a full resync.

## Migrations

Fresh projects get everything from `schema.sql`. Existing projects should apply
the files in `docs/supabase/migrations/` in date order via the SQL Editor.

Until `2026-10-17_add_golf_mode_view_style.sql` is applied, the Golf Mode View
style (Ladder/Text) is stored on-device only: the app detects the missing
`golf_mode_view_style` column (PostgREST `PGRST204`) and pushes profiles
without it. Sync of everything else is unaffected. Once applied, the setting
syncs with no app change.
