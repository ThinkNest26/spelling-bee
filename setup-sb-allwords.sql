-- =====================================================================
--  SPELLING BEE — Look, Cover, Write and Missing letters must be done
--  with ALL the child's words (not 5) to count for the semi-final.
--  New activity names (lcwca, missa) so the old "5 words" ticks no
--  longer count. Paste ALL of this into Supabase -> SQL Editor -> Run.
-- =====================================================================
create table if not exists public.sb_actw (
  student_id uuid not null references public.students(id) on delete cascade,
  act        text not null,
  word       text not null,
  done_at    timestamptz not null default now(),
  primary key (student_id, act, word)
);
alter table public.sb_actw enable row level security;
drop policy if exists sb_actw_teacher on public.sb_actw;
create policy sb_actw_teacher on public.sb_actw for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_actw to authenticated;

create or replace function public.sb_actw_mark(p_code text, p_act text, p_word text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null or p_act not in ('lcwca','missa') or length(trim(coalesce(p_word,''))) not between 1 and 40 then return null; end if;
  insert into public.sb_actw(student_id, act, word) values (s.id, p_act, trim(p_word)) on conflict do nothing;
  return json_build_object('ok', true);
end $$;
revoke all on function public.sb_actw_mark(text, text, text) from public;
grant execute on function public.sb_actw_mark(text, text, text) to anon, authenticated;

create or replace function public.sb_actw_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  return json_build_object(
    'lcwca', coalesce((select json_agg(word) from public.sb_actw where student_id = s.id and act = 'lcwca'), '[]'::json),
    'missa', coalesce((select json_agg(word) from public.sb_actw where student_id = s.id and act = 'missa'), '[]'::json));
end $$;
revoke all on function public.sb_actw_mine(text) from public;
grant execute on function public.sb_actw_mine(text) to anon, authenticated;

-- accept the new activity names
create or replace function public.sb_act_mark(p_code text, p_act text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return json_build_object('error','code'); end if;
  if p_act not in ('test','realbee','ghive','gcatch','ggarden','grace','gballoon','lcwc','miss','lcwca','missa','gap','rules','sent','weekly') then
    return json_build_object('error','act'); end if;
  insert into public.sb_acts (student_id, act) values (s.id, p_act) on conflict do nothing;
  return json_build_object('ok', true);
end $$;
revoke all on function public.sb_act_mark(text, text) from public;
grant execute on function public.sb_act_mark(text, text) to anon, authenticated;
