alter table public.user_profiles
  add column if not exists golf_mode_view_style text not null default 'text';
notify pgrst, 'reload schema';
