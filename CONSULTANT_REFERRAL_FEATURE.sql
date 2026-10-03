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
  address text,
  account_holder_name text,
  bank_name text,
  bank_account text,
  ifsc_code text,
  upi_id text,
  pan_number text,
  pan_image_url text,
  aadhaar_number text,
  aadhaar_front_url text,
  aadhaar_back_url text,
  branch_name text,
  bank_qr_url text,
  verified boolean not null default false,
  verification_status text not null default 'not_submitted',
  verification_notes text,
  verification_section text,
  verification_submitted_at timestamptz,
  verified_at timestamptz,
  section_statuses jsonb not null default '{}'::jsonb,
  verified_sections jsonb not null default '[]'::jsonb,
  profile_verified boolean not null default false,
  bank_verified boolean not null default false,
  documents_verified boolean not null default false,
  document_verified boolean not null default false,
  verification_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.consultants
  add column if not exists address text,
  add column if not exists account_holder_name text,
  add column if not exists bank_name text,
  add column if not exists bank_account text,
  add column if not exists ifsc_code text,
  add column if not exists upi_id text,
  add column if not exists pan_number text,
  add column if not exists pan_image_url text,
  add column if not exists aadhaar_number text,
  add column if not exists aadhaar_front_url text,
  add column if not exists aadhaar_back_url text,
  add column if not exists branch_name text,
  add column if not exists bank_qr_url text,
  add column if not exists verified boolean not null default false,
  add column if not exists verification_status text not null default 'not_submitted',
  add column if not exists verification_notes text,
  add column if not exists verification_section text,
  add column if not exists verification_submitted_at timestamptz,
  add column if not exists verified_at timestamptz,
  add column if not exists section_statuses jsonb not null default '{}'::jsonb,
  add column if not exists verified_sections jsonb not null default '[]'::jsonb,
  add column if not exists profile_verified boolean not null default false,
  add column if not exists bank_verified boolean not null default false,
  add column if not exists documents_verified boolean not null default false,
  add column if not exists document_verified boolean not null default false,
  add column if not exists verification_verified boolean not null default false;

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
