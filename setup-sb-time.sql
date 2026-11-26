-- =====================================================================
--  SPELLING BEE — time spent practising
--  Counts the minutes each child is actively using the website
--  (the timer pauses when they are idle or the page is hidden).
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
--  Safe to run more than once.
-- =====================================================================

create table if not exists public.sb_time (
  student_id uuid not null references public.students(id) on delete cascade,
  day        date not null,
  secs       int  not null default 0,
  primary key (student_id, day)
);
alter table public.sb_time enable row level security;
drop policy if exists sb_time_teacher on public.sb_time;
create policy sb_time_teacher on public.sb_time for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_time to authenticated;

-- add active seconds for today (Dubai time); at most 2 minutes per call and 6 hours per day
create or replace function public.sb_time_add(p_code text, p_secs int) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; d date := (now() at time zone 'Asia/Dubai')::date; n int := least(greatest(coalesce(p_secs,0),0),120);
begin
  s := public.sb_student(p_code);
  if s.id is null or n = 0 then return null; end if;
  insert into public.sb_time(student_id, day, secs) values (s.id, d, n)
    on conflict (student_id, day) do update set secs = least(public.sb_time.secs + excluded.secs, 21600);
  return json_build_object('ok', true);
end $$;
revoke all on function public.sb_time_add(text, int) from public;
grant execute on function public.sb_time_add(text, int) to anon, authenticated;

-- ---------- the 2-hour screen break after 1 hour of practice ----------
-- kept on the server so a child can't skip it by moving to another device
create table if not exists public.sb_break (
  student_id uuid primary key references public.students(id) on delete cascade,
  until      timestamptz not null
);
alter table public.sb_break enable row level security;
drop policy if exists sb_break_teacher on public.sb_break;
create policy sb_break_teacher on public.sb_break for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_break to authenticated;

-- start a break (2 hours from now) unless one is already running; returns when it ends (milliseconds)
create or replace function public.sb_break_start(p_code text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; u timestamptz;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select until into u from public.sb_break where student_id = s.id;
  if u is null or u < now() then
    u := now() + interval '2 hours';
    insert into public.sb_break(student_id, until) values (s.id, u)
      on conflict (student_id) do update set until = excluded.until;
  end if;
  return json_build_object('until', floor(extract(epoch from u) * 1000));
end $$;
revoke all on function public.sb_break_start(text) from public;
grant execute on function public.sb_break_start(text) to anon, authenticated;

-- is a break running for me?
create or replace function public.sb_break_get(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; u timestamptz;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select until into u from public.sb_break where student_id = s.id and until > now();
  if u is null then return json_build_object('until', null); end if;
  return json_build_object('until', floor(extract(epoch from u) * 1000));
end $$;
revoke all on function public.sb_break_get(text) from public;
grant execute on function public.sb_break_get(text) to anon, authenticated;
