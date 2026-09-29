-- Work2Wish: Worker experience Years / Months support
-- Run once in Supabase SQL Editor before using the new experience toggle.

alter table public.workers
  add column if not exists experience_value numeric default 0;

alter table public.workers
  add column if not exists experience_unit text default 'years';

-- Preserve existing worker experience as Years. The new columns receive
-- defaults on existing rows, so explicitly backfill any older non-zero years.
update public.workers
set experience_value = coalesce(experience_years, 0),
    experience_unit = 'years'
where coalesce(experience_years, 0) > 0
  and coalesce(experience_value, 0) = 0
  and coalesce(experience_unit, 'years') = 'years';

-- Keep values valid without changing existing rows.
update public.workers
set experience_value = greatest(coalesce(experience_value, 0), 0),
    experience_unit = case when experience_unit = 'months' then 'months' else 'years' end;
