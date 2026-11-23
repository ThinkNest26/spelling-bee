-- =====================================================================
--  SPELLING BEE — Grade semi-finals: organisers, qualifiers and what
--  the children see. Paste ALL of this into Supabase -> SQL Editor ->
--  New query -> Run. Safe to run more than once.
-- =====================================================================

-- who may set up the semi-finals (per school). While the list is empty,
-- any teacher of the school can add the first organisers.
create table if not exists public.sb_organisers (
  school_id uuid not null default public.my_school() references public.schools(id) on delete cascade,
  email     text not null,
  added_at  timestamptz not null default now(),
  primary key (school_id, email)
);
alter table public.sb_organisers enable row level security;

create or replace function public.sb_is_organiser() returns boolean
language sql stable security definer set search_path = public as $$
  select public.my_school() is not null and (
    exists (select 1 from public.sb_organisers o where o.school_id = public.my_school()
             and lower(o.email) = lower(coalesce(auth.jwt() ->> 'email','')))
    or not exists (select 1 from public.sb_organisers o where o.school_id = public.my_school()))
$$;
grant execute on function public.sb_is_organiser() to authenticated;

drop policy if exists sb_organisers_read on public.sb_organisers;
create policy sb_organisers_read on public.sb_organisers for select to authenticated using (school_id = public.my_school());
drop policy if exists sb_organisers_write on public.sb_organisers;
create policy sb_organisers_write on public.sb_organisers for insert to authenticated
  with check (school_id = public.my_school() and public.sb_is_organiser());
drop policy if exists sb_organisers_del on public.sb_organisers;
create policy sb_organisers_del on public.sb_organisers for delete to authenticated
  using (school_id = public.my_school() and public.sb_is_organiser());
grant select, insert, delete on public.sb_organisers to authenticated;

-- one semi-final per grade
create table if not exists public.sb_semis (
  id         bigint generated always as identity primary key,
  school_id  uuid not null default public.my_school() references public.schools(id) on delete cascade,
  grade      int  not null check (grade between 0 and 5),
  day        date,
  place      text not null default '',
  format     text not null default 'out' check (format in ('out','written','points')),
  per_class  int  not null default 5 check (per_class between 1 and 30),
  finalists  int  not null default 3 check (finalists between 1 and 30),
  notes      text not null default '',
  status     text not null default 'draft' check (status in ('draft','confirmed')),
  qualifiers uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  unique (school_id, grade)
);
alter table public.sb_semis enable row level security;
drop policy if exists sb_semis_read on public.sb_semis;
create policy sb_semis_read on public.sb_semis for select to authenticated using (school_id = public.my_school());
drop policy if exists sb_semis_write on public.sb_semis;
create policy sb_semis_write on public.sb_semis for insert to authenticated with check (school_id = public.my_school() and public.sb_is_organiser());
drop policy if exists sb_semis_upd on public.sb_semis;
create policy sb_semis_upd on public.sb_semis for update to authenticated
  using (school_id = public.my_school() and public.sb_is_organiser()) with check (school_id = public.my_school() and public.sb_is_organiser());
drop policy if exists sb_semis_del on public.sb_semis;
create policy sb_semis_del on public.sb_semis for delete to authenticated using (school_id = public.my_school() and public.sb_is_organiser());
grant select, insert, update, delete on public.sb_semis to authenticated;

-- what a child sees: only once the list is confirmed, and only if they qualified
create or replace function public.sb_semi_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; m public.sb_semis;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select * into m from public.sb_semis where school_id = s.school_id and grade = s.grade and status = 'confirmed' and s.id = any(qualifiers);
  if m.id is null then return null; end if;
  return json_build_object('grade', m.grade, 'day', m.day, 'place', m.place, 'format', m.format, 'notes', m.notes,
    'finalists', m.finalists, 'count', coalesce(array_length(m.qualifiers, 1), 0));
end $$;
revoke all on function public.sb_semi_mine(text) from public;
grant execute on function public.sb_semi_mine(text) to anon, authenticated;

select 'Semi-finals ready' as result;
