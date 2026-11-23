-- =====================================================================
--  SPELLING BEE — "Test me at home": the child chooses 5 words, looks at
--  them once, locks them, a grown-up tests them, then the words unlock.
--  Run setup-sb-plus.sql first. Paste ALL of this into Supabase ->
--  SQL Editor -> New query -> Run. Safe to run more than once.
-- =====================================================================
create table if not exists public.sb_hometest (
  student_id uuid not null references public.students(id) on delete cascade,
  week       date not null,                      -- Monday of the week
  words      text[] not null,
  locked_at  timestamptz,
  done_at    timestamptz,
  answers    jsonb not null default '{}'::jsonb,  -- word -> what the child wrote
  score      int,
  total      int,
  created_at timestamptz not null default now(),
  primary key (student_id, week)
);
alter table public.sb_hometest enable row level security;
drop policy if exists sb_hometest_teacher on public.sb_hometest;
create policy sb_hometest_teacher on public.sb_hometest for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_hometest to authenticated;

-- the child's own view: the words are hidden while they are locked
create or replace function public.sb_home_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; h public.sb_hometest; wk date := public.sb_x_week_start();
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select * into h from public.sb_hometest where student_id = s.id and week = wk;
  if h.student_id is null then return json_build_object('week', wk, 'state', 'none'); end if;
  return json_build_object('week', wk,
    'state', case when h.done_at is not null then 'done' when h.locked_at is not null then 'locked' else 'chosen' end,
    'n', coalesce(array_length(h.words, 1), 0),
    'words', case when h.locked_at is null or h.done_at is not null then to_json(h.words) else null end,
    'answers', case when h.done_at is not null then h.answers else null end,
    'score', h.score, 'total', h.total);
end $$;

-- choose (or change) the 5 words — only before they are locked
create or replace function public.sb_home_choose(p_code text, p_words text[]) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; wk date := public.sb_x_week_start(); w text[];
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select array_agg(x) into w from (select distinct on (lower(trim(x))) trim(x) as x from unnest(p_words) x where length(trim(x)) between 1 and 40) t;
  if coalesce(array_length(w, 1), 0) <> 5 then return json_build_object('error', 'five'); end if;
  if exists (select 1 from public.sb_hometest where student_id = s.id and week = wk and locked_at is not null) then
    return json_build_object('error', 'locked'); end if;
  insert into public.sb_hometest(student_id, week, words) values (s.id, wk, w)
  on conflict (student_id, week) do update set words = excluded.words, created_at = now();
  return json_build_object('ok', true);
end $$;

create or replace function public.sb_home_lock(p_code text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  update public.sb_hometest set locked_at = now()
   where student_id = s.id and week = public.sb_x_week_start() and locked_at is null;
  return json_build_object('ok', true);
end $$;

-- the grown-up's page: the words appear once the child has locked them
create or replace function public.sb_home_grownup(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; h public.sb_hometest; sc text;
begin
  s := public.sb_student(p_code);
  if s.id is null then return json_build_object('error', 'code'); end if;
  select name into sc from public.schools where id = s.school_id;
  select * into h from public.sb_hometest where student_id = s.id and week = public.sb_x_week_start();
  return json_build_object('name', s.first_name, 'school', sc,
    'state', case when h.student_id is null then 'none' when h.done_at is not null then 'done' when h.locked_at is not null then 'locked' else 'chosen' end,
    'words', case when h.locked_at is not null then to_json(h.words) else null end,
    'answers', case when h.done_at is not null then h.answers else null end,
    'score', h.score, 'total', h.total);
end $$;

-- the child hands in the test: marked here, then the words unlock
create or replace function public.sb_home_submit(p_code text, p_answers text[]) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; h public.sb_hometest; a jsonb := '{}'::jsonb; sc int := 0; i int; t text;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select * into h from public.sb_hometest where student_id = s.id and week = public.sb_x_week_start();
  if h.student_id is null or h.locked_at is null then return json_build_object('error', 'notlocked'); end if;
  if h.done_at is not null then return json_build_object('error', 'done'); end if;
  for i in 1 .. array_length(h.words, 1) loop
    t := left(trim(coalesce(p_answers[i], '')), 60);
    a := a || jsonb_build_object(h.words[i], t);
    if lower(t) = lower(h.words[i]) then sc := sc + 1; end if;
  end loop;
  update public.sb_hometest set done_at = now(), answers = a, score = sc, total = array_length(h.words, 1)
   where student_id = s.id and week = h.week;
  insert into public.progress(student_id) values (s.id) on conflict do nothing;
  update public.progress set stars = stars + 5 where student_id = s.id;
  return json_build_object('give', 5, 'score', sc, 'total', array_length(h.words, 1), 'words', to_json(h.words), 'answers', a);
end $$;

revoke all on function public.sb_home_mine(text), public.sb_home_choose(text,text[]), public.sb_home_lock(text),
  public.sb_home_grownup(text), public.sb_home_submit(text,text[]) from public;
grant execute on function public.sb_home_mine(text), public.sb_home_choose(text,text[]), public.sb_home_lock(text),
  public.sb_home_grownup(text), public.sb_home_submit(text,text[]) to anon, authenticated;
select 'Test me at home ready' as result;
