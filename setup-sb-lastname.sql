-- SPELLING BEE — keep each child's surname (teachers only; children still see only their first name)
-- Paste into Supabase -> SQL Editor -> New query -> Run. Safe to run more than once.
alter table public.students add column if not exists last_name text not null default '';
select 'Surnames ready' as result;
