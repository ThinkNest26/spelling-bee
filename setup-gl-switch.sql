-- =====================================================================
--  GL PRACTICE ON/OFF SWITCH for each school (Spelling Bee and Maths Quest)
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
--  Safe to run more than once. Every school starts with GL Practice ON.
-- =====================================================================
alter table public.schools add column if not exists gl_bee boolean not null default true;
alter table public.schools add column if not exists gl_mq  boolean not null default true;

-- is GL Practice switched on? (child: pass the child's code; teacher: no code)
create or replace function public.sb_gl_status(p_code text default null) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid;
begin
  if p_code is not null then sid := (public.sb_student(p_code)).school_id; else sid := public.my_school(); end if;
  return json_build_object('on', coalesce((select gl_bee from public.schools where id = sid), true));
end $$;

create or replace function public.mq_gl_status(p_code text default null) returns json
language plpgsql stable security definer set search_path = public as $$
declare sid uuid;
begin
  if p_code is not null then sid := (public.mq_kid(p_code)).school_id; else sid := public.my_school(); end if;
  return json_build_object('on', coalesce((select gl_mq from public.schools where id = sid), true));
end $$;

-- admin: see and change the switches
create or replace function public.admin_gl_list() returns json
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then return '[]'::json; end if;
  return coalesce((select json_agg(json_build_object('id', id, 'bee', gl_bee, 'mq', gl_mq)) from public.schools), '[]'::json);
end $$;

create or replace function public.admin_set_gl(p_school uuid, p_app text, p_on boolean) returns json
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then return json_build_object('error','admin'); end if;
  if p_app = 'bee' then update public.schools set gl_bee = p_on where id = p_school;
  elsif p_app = 'mq' then update public.schools set gl_mq = p_on where id = p_school;
  else return json_build_object('error','app'); end if;
  return json_build_object('ok', true);
end $$;

-- saving a GL test is refused when GL Practice is switched off
create or replace function public.sb_gl_save(p_code text, p_grade int, p_form text, p_score int, p_total int,
  p_dict int, p_dict_of int, p_areas jsonb, p_secs int) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; sc public.schools; first boolean;
begin
  s := public.sb_student(p_code);
  if s.id is null or p_form not in ('A','B') or p_total is null or p_total < 1 or p_total > 100
     or p_score < 0 or p_score > p_total then return null; end if;
  select * into sc from public.schools where id = s.school_id;
  if sc.plan_until < (now() at time zone 'Asia/Dubai')::date then return json_build_object('error','paused'); end if;
  if not coalesce(sc.gl_bee, true) then return json_build_object('error','nogl'); end if;
  first := not exists (select 1 from public.sb_gl_results where student_id = s.id and grade = p_grade and form = p_form);
  insert into public.sb_gl_results(student_id, grade, form, score, total, dict, dict_of, areas, secs)
  values (s.id, p_grade, p_form, p_score, p_total, p_dict, p_dict_of, coalesce(p_areas, '{}'::jsonb), least(greatest(coalesce(p_secs,0),0), 36000));
  if first then
    insert into public.progress(student_id) values (s.id) on conflict do nothing;
    update public.progress set stars = stars + 10 where student_id = s.id;
  end if;
  return json_build_object('give', case when first then 10 else 0 end);
end $$;

create or replace function public.mq_gl_save(p_code text, p_grade int, p_form text, p_score int, p_total int,
  p_mental int, p_mental_of int, p_areas jsonb, p_secs int) returns json
language plpgsql security definer set search_path = public as $$
declare k public.mq_students; first boolean; st int;
begin
  k := public.mq_kid(p_code);
  if k.id is null or p_form not in ('A','B') or p_total is null or p_total < 1 or p_total > 100
     or p_score < 0 or p_score > p_total then return null; end if;
  if not coalesce((select gl_mq from public.schools where id = k.school_id), true) then return json_build_object('error','nogl'); end if;
  first := not exists (select 1 from public.mq_gl_results where student_id = k.id and grade = p_grade and form = p_form);
  insert into public.mq_gl_results(student_id, grade, form, score, total, mental, mental_of, areas, secs)
  values (k.id, p_grade, p_form, p_score, p_total, p_mental, p_mental_of, coalesce(p_areas, '{}'::jsonb), least(greatest(coalesce(p_secs,0),0), 36000));
  if first then update public.mq_progress set stars = stars + 10 where student_id = k.id returning stars into st;
  else select stars into st from public.mq_progress where student_id = k.id; end if;
  return json_build_object('stars', st, 'give', case when first then 10 else 0 end);
end $$;

revoke all on function public.sb_gl_status(text), public.mq_gl_status(text), public.admin_gl_list(), public.admin_set_gl(uuid,text,boolean) from public;
grant execute on function public.sb_gl_status(text), public.mq_gl_status(text) to anon, authenticated;
grant execute on function public.admin_gl_list(), public.admin_set_gl(uuid,text,boolean) to authenticated;
select 'GL Practice switch ready' as result;
