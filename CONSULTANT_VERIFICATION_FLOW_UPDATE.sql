-- Work2Wish Consultant profile + section-wise verification flow
-- Run once in Supabase Dashboard -> SQL Editor after deploying this version.
-- Safe to re-run: all schema additions use IF NOT EXISTS and the backfill uses ON CONFLICT.

begin;

alter table public.consultants
  add column if not exists address text,
  add column if not exists account_holder_name text,
  add column if not exists bank_name text,
  add column if not exists bank_account text,
  add column if not exists ifsc_code text,
  add column if not exists branch_name text,
  add column if not exists upi_id text,
  add column if not exists bank_qr_url text,
  add column if not exists pan_number text,
  add column if not exists pan_image_url text,
  add column if not exists aadhaar_number text,
  add column if not exists aadhaar_front_url text,
  add column if not exists aadhaar_back_url text,
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

create table if not exists public.user_verification_sections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text check (role in ('worker', 'employer', 'consultant', 'admin')),
  section text not null check (section in ('profile', 'documents', 'bank', 'identity', 'location', 'admin_message')),
  status text not null default 'draft' check (status in ('draft', 'pending', 'verified', 'rejected')),
  submitted_at timestamptz,
  verified_at timestamptz,
  verified_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, section)
);

create index if not exists idx_user_verification_sections_user
  on public.user_verification_sections(user_id);
create index if not exists idx_user_verification_sections_status
  on public.user_verification_sections(status, updated_at desc);

alter table public.user_verification_sections enable row level security;
drop policy if exists "users_read_own_verification_sections" on public.user_verification_sections;
create policy "users_read_own_verification_sections"
on public.user_verification_sections
for select
to authenticated
using (auth.uid() = user_id);

-- The durable verification-state table existed before Consultant was added.
-- Extend only its role check so Consultant can use the exact same card lifecycle.
do $$
declare
  constraint_row record;
begin
  if to_regclass('public.user_verification_sections') is not null then
    for constraint_row in
      select conname
      from pg_constraint
      where conrelid = 'public.user_verification_sections'::regclass
        and contype = 'c'
        and pg_get_constraintdef(oid) ilike '%role%'
    loop
      execute format('alter table public.user_verification_sections drop constraint %I', constraint_row.conname);
    end loop;

    execute 'alter table public.user_verification_sections add constraint user_verification_sections_role_check check (role in (''worker'', ''employer'', ''consultant'', ''admin''))';
  end if;
end $$;

-- Backfill the three Consultant cards without touching existing states.
insert into public.user_verification_sections (user_id, role, section, status, submitted_at, verified_at, updated_at)
select
  c.user_id,
  'consultant',
  s.section,
  case
    when coalesce(c.section_statuses ->> s.section, '') in ('verified','approved','done') then 'verified'
    when coalesce(c.section_statuses ->> s.section, '') in ('pending','submitted','review','in_review') then 'pending'
    when s.section = 'profile' and coalesce(c.profile_verified, false) then 'verified'
    when s.section = 'bank' and coalesce(c.bank_verified, false) then 'verified'
    when s.section = 'documents' and (coalesce(c.documents_verified, false) or coalesce(c.document_verified, false) or coalesce(c.verification_verified, false)) then 'verified'
    when c.verification_status in ('pending','submitted') and coalesce(c.verification_section, 'profile') in (s.section, case when s.section='documents' then 'verification' else s.section end) then 'pending'
    when coalesce(c.verified, false) then 'verified'
    else 'draft'
  end,
  case when c.verification_status in ('pending','submitted') then c.verification_submitted_at else null end,
  case when coalesce(c.verified, false) then coalesce(c.verified_at, now()) else null end,
  now()
from public.consultants c
cross join (values ('profile'), ('documents'), ('bank')) as s(section)
on conflict (user_id, section) do nothing;

commit;
