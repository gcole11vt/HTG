-- HTG Supabase schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query).
-- Tables mirror the SwiftData models 1:1; column names match the CodingKeys
-- in HTG/Core/Services/Sync/SyncRecords.swift.
--
-- Every table is scoped to the signed-in user via `user_id default auth.uid()`
-- plus row-level security, so the app never sends user_id explicitly.

-- ============ Tables ============

create table public.user_profiles (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null default '',
  handicap integer not null default 18,
  primary_shot_type text not null default 'Full',
  mantra text not null default '',
  show_pre_shot_routine boolean not null default true,
  show_mantra boolean not null default true,
  updated_at timestamptz not null
);

create table public.clubs (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  nickname text not null default '',
  sort_order integer not null default 0,
  is_archived boolean not null default false,
  updated_at timestamptz not null
);

create table public.shot_types (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  club_id uuid references public.clubs (id) on delete cascade,
  name text not null,
  carry_distance integer not null default 0,
  sort_order integer not null default 0,
  is_archived boolean not null default false,
  archived_date timestamptz,
  updated_at timestamptz not null
);

create table public.range_sessions (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  date timestamptz not null,
  club_name text not null,
  shot_type_name text not null,
  updated_at timestamptz not null
);

create table public.shots (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  session_id uuid references public.range_sessions (id) on delete cascade,
  distance integer not null,
  date timestamptz not null,
  is_from_voice boolean not null default false,
  updated_at timestamptz not null
);

create table public.pre_shot_routine_items (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  profile_id uuid references public.user_profiles (id) on delete cascade,
  text text not null,
  sort_order integer not null default 0,
  updated_at timestamptz not null
);

create table public.swing_thoughts (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  profile_id uuid references public.user_profiles (id) on delete cascade,
  text text not null,
  tag_type text not null default 'all',
  tag_value text not null default '',
  updated_at timestamptz not null
);

create table public.app_settings (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  yardage_range_percentage integer not null default 15,
  updated_at timestamptz not null
);

-- Cross-device delete propagation. One row per hard-deleted record.
create table public.sync_deletions (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  record_id uuid not null,
  entity_name text not null,
  deleted_at timestamptz not null,
  primary key (user_id, record_id)
);

-- ============ Indexes for delta pulls ============

create index user_profiles_user_updated_idx on public.user_profiles (user_id, updated_at);
create index clubs_user_updated_idx on public.clubs (user_id, updated_at);
create index shot_types_user_updated_idx on public.shot_types (user_id, updated_at);
create index range_sessions_user_updated_idx on public.range_sessions (user_id, updated_at);
create index shots_user_updated_idx on public.shots (user_id, updated_at);
create index pre_shot_routine_items_user_updated_idx on public.pre_shot_routine_items (user_id, updated_at);
create index swing_thoughts_user_updated_idx on public.swing_thoughts (user_id, updated_at);
create index app_settings_user_updated_idx on public.app_settings (user_id, updated_at);
create index sync_deletions_user_deleted_idx on public.sync_deletions (user_id, deleted_at);

-- ============ Row-level security ============

alter table public.user_profiles enable row level security;
alter table public.clubs enable row level security;
alter table public.shot_types enable row level security;
alter table public.range_sessions enable row level security;
alter table public.shots enable row level security;
alter table public.pre_shot_routine_items enable row level security;
alter table public.swing_thoughts enable row level security;
alter table public.app_settings enable row level security;
alter table public.sync_deletions enable row level security;

create policy "Users manage own rows" on public.user_profiles
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.clubs
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.shot_types
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.range_sessions
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.shots
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.pre_shot_routine_items
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.swing_thoughts
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.app_settings
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users manage own rows" on public.sync_deletions
  for all using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
