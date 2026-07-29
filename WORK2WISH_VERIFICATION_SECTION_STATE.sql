-- Work2Wish durable section-wise verification workflow
-- Run once in Supabase Dashboard -> SQL Editor.
-- This keeps each card independent and consistent on localhost and app.work2wish.com:
-- draft (red) -> pending (yellow) -> verified (green).

begin;

-- Ensure the existing role tables contain the compatibility fields used by
-- both the old UI and the new durable section-state table.
alter table if exists public.workers
  add column if not exists resume_url text,
  add column if not exists section_statuses jsonb not null default '{}'::jsonb,
  add column if not exists verified_sections jsonb not null default '[]'::jsonb,
  add column if not exists profile_verified boolean not null default false,
  add column if not exists bank_verified boolean not null default false,
  add column if not exists documents_verified boolean not null default false,
  add column if not exists document_verified boolean not null default false,
  add column if not exists verification_verified boolean not null default false,
  add column if not exists verification_section text,
  add column if not exists verification_submitted_at timestamptz,
  add column if not exists verified_at timestamptz;

alter table if exists public.employers
  add column if not exists section_statuses jsonb not null default '{}'::jsonb,
  add column if not exists verified_sections jsonb not null default '[]'::jsonb,
  add column if not exists profile_verified boolean not null default false,
  add column if not exists documents_verified boolean not null default false,
  add column if not exists document_verified boolean not null default false,
  add column if not exists verification_verified boolean not null default false,
  add column if not exists verification_section text,
  add column if not exists verification_submitted_at timestamptz,
  add column if not exists verified_at timestamptz;

create table if not exists public.user_verification_sections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text check (role in ('worker', 'employer', 'admin')),
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

-- Users may read only their own card states. All writes are performed by the
-- server with SUPABASE_SERVICE_ROLE_KEY, which bypasses RLS.
drop policy if exists "users_read_own_verification_sections" on public.user_verification_sections;
create policy "users_read_own_verification_sections"
on public.user_verification_sections
for select
to authenticated
using (auth.uid() = user_id);

-- Backfill worker states from existing columns/JSON without overwriting rows.
insert into public.user_verification_sections (user_id, role, section, status, verified_at, updated_at)
select
  w.user_id,
  'worker',
  s.section,
  case
    when coalesce(w.section_statuses ->> s.section, '') in ('verified','approved','done') then 'verified'
    when coalesce(w.section_statuses ->> s.section, '') in ('pending','submitted','review','in_review') then 'pending'
    when s.section = 'profile' and coalesce(w.profile_verified, false) then 'verified'
    when s.section = 'bank' and coalesce(w.bank_verified, false) then 'verified'
    when s.section = 'documents' and (coalesce(w.documents_verified, false) or coalesce(w.document_verified, false) or coalesce(w.verification_verified, false)) then 'verified'
    when w.verification_status in ('pending','submitted') and coalesce(w.verification_section, 'profile') in (s.section, case when s.section='documents' then 'verification' else s.section end) then 'pending'
    when coalesce(w.verified, false) then 'verified'
    else 'draft'
  end,
  case when coalesce(w.verified, false) then coalesce(w.verified_at, now()) else null end,
  now()
from public.workers w
cross join (values ('profile'), ('documents'), ('bank')) as s(section)
on conflict (user_id, section) do nothing;

-- Backfill employer states from existing columns/JSON without overwriting rows.
insert into public.user_verification_sections (user_id, role, section, status, verified_at, updated_at)
select
  e.user_id,
  'employer',
  s.section,
  case
    when coalesce(e.section_statuses ->> s.section, '') in ('verified','approved','done') then 'verified'
    when coalesce(e.section_statuses ->> s.section, '') in ('pending','submitted','review','in_review') then 'pending'
    when s.section = 'profile' and coalesce(e.profile_verified, false) then 'verified'
    when s.section = 'documents' and (coalesce(e.documents_verified, false) or coalesce(e.document_verified, false) or coalesce(e.verification_verified, false)) then 'verified'
    when e.verification_status in ('pending','submitted') and coalesce(e.verification_section, 'profile') in (s.section, case when s.section='documents' then 'verification' else s.section end) then 'pending'
    when coalesce(e.verified, false) then 'verified'
    else 'draft'
  end,
  case when coalesce(e.verified, false) then coalesce(e.verified_at, now()) else null end,
  now()
from public.employers e
cross join (values ('profile'), ('documents')) as s(section)
on conflict (user_id, section) do nothing;

commit;

-- Optional check:
-- select user_id, role, section, status, updated_at
-- from public.user_verification_sections
-- order by updated_at desc;
