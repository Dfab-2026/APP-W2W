-- Work2Wish engagement push scheduler for Vercel Hobby deployments
-- This replaces the Vercel Cron entry. It does NOT replace the existing
-- Work2Wish Web Push/service-worker flow; it only schedules the existing
-- /api/cron/engagement endpoint from Supabase.
--
-- BEFORE RUNNING:
-- 1) Replace https://YOUR-WORK2WISH-DOMAIN.vercel.app with the production URL.
-- 2) Replace CHANGE-ME-TO-A-LONG-RANDOM-SECRET with a strong random value.
-- 3) Add the SAME secret in Vercel Environment Variables as CRON_SECRET.
-- 4) Run this file once in Supabase SQL Editor.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists supabase_vault with schema vault;

-- Replace old values safely when re-running this setup.
do $$
declare
  existing_id uuid;
begin
  select id into existing_id from vault.secrets where name = 'work2wish_site_url' limit 1;
  if existing_id is null then
    perform vault.create_secret('https://YOUR-WORK2WISH-DOMAIN.vercel.app', 'work2wish_site_url', 'Work2Wish production site URL');
  else
    perform vault.update_secret(existing_id, 'https://YOUR-WORK2WISH-DOMAIN.vercel.app', 'work2wish_site_url', 'Work2Wish production site URL');
  end if;

  select id into existing_id from vault.secrets where name = 'work2wish_cron_secret' limit 1;
  if existing_id is null then
    perform vault.create_secret('CHANGE-ME-TO-A-LONG-RANDOM-SECRET', 'work2wish_cron_secret', 'Work2Wish engagement scheduler secret');
  else
    perform vault.update_secret(existing_id, 'CHANGE-ME-TO-A-LONG-RANDOM-SECRET', 'work2wish_cron_secret', 'Work2Wish engagement scheduler secret');
  end if;
end $$;

-- Remove an older copy of the same job if this script is re-run.
do $$
declare
  existing_job bigint;
begin
  select jobid into existing_job from cron.job where jobname = 'work2wish-engagement-push' limit 1;
  if existing_job is not null then
    perform cron.unschedule(existing_job);
  end if;
end $$;

-- Run once per day at 10:00 AM India time (04:30 UTC).
-- The API also enforces one Chrome engagement push per user per India calendar day.
select cron.schedule(
  'work2wish-engagement-push',
  '30 4 * * *',
  $$
  select net.http_get(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'work2wish_site_url') || '/api/cron/engagement',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'work2wish_cron_secret')
    ),
    timeout_milliseconds := 10000
  ) as request_id;
  $$
);

-- Verify the job exists:
-- select jobid, jobname, schedule, active from cron.job where jobname = 'work2wish-engagement-push';
-- View recent runs:
-- select * from cron.job_run_details where jobid = (select jobid from cron.job where jobname = 'work2wish-engagement-push') order by start_time desc limit 20;
