-- Run once in Supabase SQL Editor before deploying the mobile signup/login build.
-- Email remains unique when present, but mobile-only accounts do not require one.

alter table public.user_profiles
  alter column email drop not null;

alter table public.user_profiles
  add column if not exists phone text;

