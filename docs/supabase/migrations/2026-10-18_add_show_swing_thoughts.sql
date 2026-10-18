alter table public.user_profiles
  add column if not exists show_swing_thoughts boolean not null default true;
notify pgrst, 'reload schema';
