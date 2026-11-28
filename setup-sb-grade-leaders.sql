-- =====================================================================
--  SPELLING BEE — 🏅 Grade leaderboard
--  Each child sees the top 10 in THEIR OWN GRADE at their school
--  (ranked by secure 🔵 words), plus their own place.
--  Children never see other grades. Teachers see every grade on the
--  teacher page.
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
--  Safe to run more than once.
-- =====================================================================

create or replace function public.sb_grade_leaders(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; res json;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  with kids as (
    select st.id, st.first_name, st.class_name,
           coalesce(to_jsonb(p.avatar), '{}'::jsonb) as avatar,
           (select count(*) from jsonb_object_keys(coalesce(p.secure, '{}'::jsonb)))::int as sec
      from public.students st
      left join public.progress p on p.student_id = st.id
     where st.school_id = s.school_id and st.grade = s.grade and coalesce(st.active, true)
  ), ranked as (
    select k.*, rank() over (order by k.sec desc) as place
      from kids k where k.sec > 0
  )
  select json_build_object(
    'grade',   s.grade,
    'players', (select count(*) from ranked),
    'top',     coalesce((select json_agg(json_build_object('place', r.place, 'name', r.first_name, 'cls', r.class_name,
                          'avatar', r.avatar, 'sec', r.sec, 'me', r.id = s.id) order by r.place, r.first_name)
                         from (select * from ranked order by place, first_name limit 10) r), '[]'::json),
    'mine',    (select json_build_object('place', r.place, 'sec', r.sec) from ranked r where r.id = s.id)
  ) into res;
  return res;
end $$;
revoke all on function public.sb_grade_leaders(text) from public;
grant execute on function public.sb_grade_leaders(text) to anon, authenticated;

select 'Grade leaderboards ready' as result;
