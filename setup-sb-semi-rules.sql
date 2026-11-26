-- =====================================================================
--  SPELLING BEE — semi-final fair play: records how many times a child
--  left the semi-final page during the test.
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
-- =====================================================================
alter table public.sb_semi_results add column if not exists leaves int not null default 0;

create or replace function public.sb_semi_submit(p_code text, p_answers jsonb, p_secs int, p_leaves int) returns json
language plpgsql security definer set search_path = public as $$
declare r json; s public.students;
begin
  r := public.sb_semi_submit(p_code, p_answers, p_secs);
  if (r->>'ok') = 'true' then
    s := public.sb_student(p_code);
    update public.sb_semi_results x set leaves = greatest(0, least(coalesce(p_leaves, 0), 999))
      from public.sb_semis m
     where x.semi_id = m.id and x.student_id = s.id and m.school_id = s.school_id and m.grade = s.grade;
  end if;
  return r;
end $$;
revoke all on function public.sb_semi_submit(text, jsonb, int, int) from public;
grant execute on function public.sb_semi_submit(text, jsonb, int, int) to anon, authenticated;
