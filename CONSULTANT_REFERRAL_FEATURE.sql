-- Work2Wish Consultant Referral Feature
-- Run once in Supabase SQL Editor before using Consultant accounts.

begin;

-- Extend the account role constraint without changing existing rows.
-- First remove the known modern constraint name, then remove any older role check
-- that may have been created with a different/generated name.
alter table public.user_profiles drop constraint if exists user_profiles_role_check;

do $$
declare
  constraint_name text;
begin
  select c.conname
    into constraint_name
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  where n.nspname = 'public'
    and t.relname = 'user_profiles'
    and c.contype = 'c'
    and pg_get_constraintdef(c.oid) ilike '%role%'
  limit 1;

  if constraint_name is not null then
    execute format('alter table public.user_profiles drop constraint %I', constraint_name);
  end if;
end $$;

alter table public.user_profiles
  add constraint user_profiles_role_check
  check (role in ('worker','employer','consultant','admin'));

create table if not exists public.consultants (
  user_id uuid primary key references public.user_profiles(id) on delete cascade,
  referral_code text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_consultants_referral_code
  on public.consultants(referral_code);

create table if not exists public.consultant_referrals (
  id uuid primary key default gen_random_uuid(),
  consultant_id uuid not null references public.consultants(user_id) on delete cascade,
  referred_user_id uuid not null references public.user_profiles(id) on delete cascade,
  referred_role text not null check (referred_role in ('worker','employer')),
  status text not null default 'registered' check (status in ('registered','verified')),
  points_awarded boolean not null default false,
  registered_at timestamptz not null default now(),
  last_login_at timestamptz not null default now(),
  login_count integer not null default 1 check (login_count >= 1),
  verified_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (referred_user_id)
);

create index if not exists idx_consultant_referrals_consultant
  on public.consultant_referrals(consultant_id, registered_at desc);
create index if not exists idx_consultant_referrals_status
  on public.consultant_referrals(consultant_id, status);

alter table public.consultants enable row level security;
alter table public.consultant_referrals enable row level security;

-- These tables are intentionally accessed through the authenticated Next.js API
-- using the service role. No broad client-side select/write policy is added.

commit;
