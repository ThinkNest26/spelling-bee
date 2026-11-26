-- =====================================================================
--  SPELLING BEE — semi-final dates as a range (from – to), e.g.
--  Thursday 14 – Friday 15 January. The online semi-final is open on
--  every day in the range; each child still gets one go only.
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
-- =====================================================================
alter table public.sb_semis add column if not exists day_end date;
update public.sb_semis set day_end = day where day_end is null and day is not null;

-- what a child sees (adds the online test: open on the day, words only while open)
create or replace function public.sb_semi_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; m public.sb_semis; isauto boolean; r public.sb_semi_results; today date; isopen boolean;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  isauto := exists (select 1 from public.sb_semi_auto where student_id = s.id and grade = s.grade);
  select * into m from public.sb_semis where school_id = s.school_id and grade = s.grade and status = 'confirmed' and s.id = any(qualifiers);
  if m.id is not null then
    today := (now() at time zone 'Asia/Dubai')::date;
    select * into r from public.sb_semi_results where semi_id = m.id and student_id = s.id;
    isopen := m.format = 'online' and coalesce(today between m.day and coalesce(m.day_end, m.day), false) and coalesce(array_length(m.words, 1), 0) > 0;
    return json_build_object('grade', m.grade, 'day', m.day, 'day_end', coalesce(m.day_end, m.day), 'place', m.place, 'format', m.format, 'notes', m.notes,
      'finalists', m.finalists, 'count', coalesce(array_length(m.qualifiers, 1), 0), 'auto', isauto,
      'online', m.format = 'online', 'open', isopen, 'n', coalesce(array_length(m.words, 1), 0),
      'done', r.id is not null, 'score', r.score, 'total', r.total,
      'words', case when isopen and r.id is null then to_json(m.words) else null end);
  end if;
  if isauto then return json_build_object('grade', s.grade, 'auto', true); end if;
  return null;
end $$;
revoke all on function public.sb_semi_mine(text) from public;
grant execute on function public.sb_semi_mine(text) to anon, authenticated;

-- the child hands in their semi-final; the database marks it (one go only)
create or replace function public.sb_semi_submit(p_code text, p_answers jsonb, p_secs int) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; m public.sb_semis; w text; sc int := 0; tot int; clean jsonb := '{}'::jsonb; typed text;
begin
  s := public.sb_student(p_code);
  if s.id is null then return json_build_object('error','code'); end if;
  select * into m from public.sb_semis where school_id = s.school_id and grade = s.grade and status = 'confirmed'
     and format = 'online' and s.id = any(qualifiers);
  if m.id is null then return json_build_object('error','notin'); end if;
  if m.day is null or not ((now() at time zone 'Asia/Dubai')::date between m.day and coalesce(m.day_end, m.day)) then return json_build_object('error','closed'); end if;
  if exists (select 1 from public.sb_semi_results where semi_id = m.id and student_id = s.id) then
    return json_build_object('error','done');
  end if;
  tot := coalesce(array_length(m.words, 1), 0);
  if tot = 0 then return json_build_object('error','nowords'); end if;
  foreach w in array m.words loop
    typed := left(coalesce(p_answers ->> w, ''), 60);
    clean := clean || jsonb_build_object(w, typed);
    if lower(btrim(typed)) = lower(w) then sc := sc + 1; end if;
  end loop;
  insert into public.sb_semi_results (semi_id, student_id, score, total, answers, secs)
       values (m.id, s.id, sc, tot, clean, greatest(0, least(coalesce(p_secs, 0), 86400)));
  return json_build_object('ok', true, 'score', sc, 'total', tot);
end $$;
revoke all on function public.sb_semi_submit(text, jsonb, int) from public;
grant execute on function public.sb_semi_submit(text, jsonb, int) to anon, authenticated;

select 'Semi-final date range ready' as result;
