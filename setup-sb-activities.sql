-- =====================================================================
--  SPELLING BEE — every activity must be finished once (family challenge
--  and Race a friend are optional) before a child can reach the
--  semi-final, together with securing 85% of their words.
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
-- =====================================================================

create table if not exists public.sb_acts (
  student_id uuid not null references public.students(id) on delete cascade,
  act        text not null,
  done_at    timestamptz not null default now(),
  primary key (student_id, act)
);
alter table public.sb_acts enable row level security;
drop policy if exists sb_acts_teacher on public.sb_acts;
create policy sb_acts_teacher on public.sb_acts for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_acts to authenticated;

create or replace function public.sb_act_mark(p_code text, p_act text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return json_build_object('error','code'); end if;
  if p_act not in ('test','realbee','ghive','gcatch','ggarden','grace','gballoon','lcwc','miss','gap','rules','sent','weekly') then
    return json_build_object('error','act'); end if;
  insert into public.sb_acts (student_id, act) values (s.id, p_act) on conflict do nothing;
  return json_build_object('ok', true);
end $$;
revoke all on function public.sb_act_mark(text, text) from public;
grant execute on function public.sb_act_mark(text, text) to anon, authenticated;

create or replace function public.sb_act_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return '[]'::json; end if;
  return coalesce((select json_agg(act) from public.sb_acts where student_id = s.id), '[]'::json);
end $$;
revoke all on function public.sb_act_mine(text) from public;
grant execute on function public.sb_act_mine(text) to anon, authenticated;

-- the 85% check now also needs every compulsory activity
create or replace function public.sb_semi_claim(p_code text, p_total int) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; n int; need int; missing int;
begin
  s := public.sb_student(p_code);
  if s.id is null then return json_build_object('error','code'); end if;
  if exists (select 1 from public.sb_semi_auto where student_id = s.id and grade = s.grade) then
    return json_build_object('ok', true, 'new', false);
  end if;
  if p_total is null or p_total < 10 or p_total > 500 then return json_build_object('error','total'); end if;
  select count(*) into missing from unnest(array['test','ghive','gcatch','ggarden','grace','gballoon','lcwc','miss','gap','rules','sent']) a
   where not exists (select 1 from public.sb_acts x where x.student_id = s.id and x.act = a);
  if missing > 0 then return json_build_object('ok', false, 'acts', missing); end if;
  select count(*) into n
    from public.progress p, jsonb_each_text(coalesce(to_jsonb(p.words), '{}'::jsonb)) e
   where p.student_id = s.id and e.value ~ '^[0-9]+$' and e.value::int >= 2;
  need := ceil(p_total * 0.85);
  if n < need then return json_build_object('ok', false, 'secured', n, 'need', need); end if;
  insert into public.sb_semi_auto (student_id, school_id, grade, secured, total)
       values (s.id, s.school_id, s.grade, n, p_total)
  on conflict (student_id) do update set grade = excluded.grade, secured = excluded.secured,
       total = excluded.total, qualified_at = now();
  update public.sb_semis set qualifiers = array_append(qualifiers, s.id), updated_at = now()
   where school_id = s.school_id and grade = s.grade and not (s.id = any(qualifiers));
  return json_build_object('ok', true, 'new', true);
end $$;
revoke all on function public.sb_semi_claim(text, int) from public;
grant execute on function public.sb_semi_claim(text, int) to anon, authenticated;

select 'Activities rule ready' as result;
