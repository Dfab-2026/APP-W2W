-- Work2Wish Consultant minimal profile extension
-- Run once in Supabase SQL Editor after deploying this version.

begin;

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

commit;
