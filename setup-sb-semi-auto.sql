-- =====================================================================
--  SPELLING BEE — 85% rule: children who secure 85% of their grade's
--  words go into their grade semi-final automatically.
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
--  Safe to run more than once.
-- =====================================================================

create table if not exists public.sb_semi_auto (
  student_id   uuid primary key references public.students(id) on delete cascade,
  school_id    uuid not null references public.schools(id) on delete cascade,
  grade        int  not null,
  secured      int  not null,
  total        int  not null,
  qualified_at timestamptz not null default now()
);
alter table public.sb_semi_auto enable row level security;
drop policy if exists sb_semi_auto_teacher on public.sb_semi_auto;
create policy sb_semi_auto_teacher on public.sb_semi_auto for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_semi_auto to authenticated;

-- the child's page asks this when they reach 85%; the database checks it itself
create or replace function public.sb_semi_claim(p_code text, p_total int) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; n int; need int;
begin
  s := public.sb_student(p_code);
  if s.id is null then return json_build_object('error','code'); end if;
  if exists (select 1 from public.sb_semi_auto where student_id = s.id and grade = s.grade) then
    return json_build_object('ok', true, 'new', false);
  end if;
  if p_total is null or p_total < 10 or p_total > 500 then return json_build_object('error','total'); end if;
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

-- whenever a semi-final is created or saved, the 85% children are always on the list
create or replace function public.sb_semis_add_auto() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.qualifiers := array(select distinct x from unnest(new.qualifiers || coalesce((
      select array_agg(a.student_id) from public.sb_semi_auto a join public.students st on st.id = a.student_id
       where a.school_id = new.school_id and a.grade = new.grade and st.grade = new.grade), '{}'::uuid[])) x);
  return new;
end $$;
revoke all on function public.sb_semis_add_auto() from public, anon, authenticated;
drop trigger if exists sb_semis_auto_trg on public.sb_semis;
create trigger sb_semis_auto_trg before insert or update on public.sb_semis
  for each row execute function public.sb_semis_add_auto();

-- what a child sees: a confirmed semi-final they're in, or their 85% place
create or replace function public.sb_semi_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; m public.sb_semis; isauto boolean;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  isauto := exists (select 1 from public.sb_semi_auto where student_id = s.id and grade = s.grade);
  select * into m from public.sb_semis where school_id = s.school_id and grade = s.grade and status = 'confirmed' and s.id = any(qualifiers);
  if m.id is not null then
    return json_build_object('grade', m.grade, 'day', m.day, 'place', m.place, 'format', m.format, 'notes', m.notes,
      'finalists', m.finalists, 'count', coalesce(array_length(m.qualifiers, 1), 0), 'auto', isauto);
  end if;
  if isauto then return json_build_object('grade', s.grade, 'auto', true); end if;
  return null;
end $$;
revoke all on function public.sb_semi_mine(text) from public;
grant execute on function public.sb_semi_mine(text) to anon, authenticated;

-- add children already on an existing semi-final list for their grade
update public.sb_semis set updated_at = now();

select '85% semi-final rule ready' as result;
