-- =====================================================================
--  SPELLING BEE — private parent links. Each child gets a long random
--  link for their grown-ups. It only shows progress (it can't be used to
--  sign in), and it isn't the bee code. Run setup-sb-plus.sql and
--  setup-sb-home.sql first. Paste ALL of this into Supabase -> SQL
--  Editor -> New query -> Run. Safe to run more than once.
-- =====================================================================
create table if not exists public.sb_parent_links (
  student_id uuid primary key references public.students(id) on delete cascade,
  token      text not null unique,
  created_at timestamptz not null default now()
);
alter table public.sb_parent_links enable row level security;
drop policy if exists sb_parent_links_teacher on public.sb_parent_links;
create policy sb_parent_links_teacher on public.sb_parent_links for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_parent_links to authenticated;

create or replace function public.sb_new_parent_token() returns text language sql volatile as $$
  select substr(replace(gen_random_uuid()::text, '-', ''), 1, 16)
$$;

-- the child's page asks for its own parent link
create or replace function public.sb_parent_token(p_code text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; t text;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select token into t from public.sb_parent_links where student_id = s.id;
  if t is null then
    t := public.sb_new_parent_token();
    insert into public.sb_parent_links(student_id, token) values (s.id, t) on conflict (student_id) do nothing;
    select token into t from public.sb_parent_links where student_id = s.id;
  end if;
  return json_build_object('token', t);
end $$;

-- teachers: make sure every child in the school has a link (for printed reports)
create or replace function public.sb_parent_tokens() returns json
language plpgsql security definer set search_path = public as $$
begin
  if public.my_school() is null then return '[]'::json; end if;
  insert into public.sb_parent_links(student_id, token)
  select k.id, public.sb_new_parent_token() from public.students k
   where k.school_id = public.my_school() and not exists (select 1 from public.sb_parent_links l where l.student_id = k.id)
  on conflict do nothing;
  return coalesce((select json_agg(json_build_object('student_id', l.student_id, 'token', l.token))
    from public.sb_parent_links l join public.students k on k.id = l.student_id where k.school_id = public.my_school()), '[]'::json);
end $$;

-- the parent page: progress only
create or replace function public.sb_parent_view(p_token text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; p jsonb; sc public.schools; h public.sb_hometest; wk date := public.sb_x_week_start(); res json;
begin
  select k.* into s from public.sb_parent_links l join public.students k on k.id = l.student_id
   where l.token = trim(coalesce(p_token, '')) and k.active;
  if s.id is null then return json_build_object('error', 'link'); end if;
  select * into sc from public.schools where id = s.school_id;
  select to_jsonb(x) into p from public.progress x where x.student_id = s.id;
  p := coalesce(p, '{}'::jsonb);
  select * into h from public.sb_hometest where student_id = s.id and week = wk;
  res := json_build_object(
    'name', s.first_name, 'grade', s.grade, 'class', s.class_name, 'school', sc.name, 'slug', sc.slug,
    'stars', coalesce((p->>'stars')::int, 0), 'attempts', coalesce((p->>'attempts')::int, 0), 'correct', coalesce((p->>'correct')::int, 0),
    'streak', coalesce((p->>'streak')::int, 0), 'streak_day', p->>'streak_day', 'best_streak', coalesce((p->>'best_streak')::int, 0),
    'last_seen', p->>'last_seen',
    'secure', (select count(*) from jsonb_each_text(coalesce(p->'words','{}'::jsonb)) e where e.value ~ '^\d+$' and e.value::int >= 2),
    'tricky', coalesce((select json_agg(k) from (select e.key as k from jsonb_each_text(coalesce(p->'tricky','{}'::jsonb)) e
                 where coalesce((p->'words'->>e.key)::int, 0) < 2 order by e.value::int desc limit 12) t), '[]'::json),
    'review', json_build_object(
       'learning', (select count(*) from public.sb_review r where r.student_id = s.id and not r.mastered),
       'mastered', (select count(*) from public.sb_review r where r.student_id = s.id and r.mastered),
       'words', coalesce((select json_agg(word) from (select word from public.sb_review r where r.student_id = s.id and not r.mastered order by due limit 12) t), '[]'::json)),
    'home', case when h.student_id is null then json_build_object('state', 'none')
                 else json_build_object('state', case when h.done_at is not null then 'done' when h.locked_at is not null then 'locked' else 'chosen' end,
                   'words', case when h.locked_at is not null then to_json(h.words) else null end,
                   'answers', case when h.done_at is not null then h.answers else null end, 'score', h.score, 'total', h.total) end,
    'weekly', coalesce((select json_agg(json_build_object('title', w.title, 'post_from', w.post_from,
        'pre', (select json_build_object('score', r.score, 'total', r.total) from public.sb_weekly_results r where r.weekly_id = w.id and r.student_id = s.id and r.kind = 'pre'),
        'post', (select json_build_object('score', r.score, 'total', r.total, 'challenge', r.challenge) from public.sb_weekly_results r where r.weekly_id = w.id and r.student_id = s.id and r.kind = 'post'))
        order by w.created_at desc)
      from (select * from public.sb_weekly where school_id = s.school_id and grade = s.grade
              and (class_name = '' or lower(class_name) = lower(s.class_name)) order by created_at desc limit 4) w), '[]'::json),
    'gl', case when coalesce(sc.gl_bee, true) then coalesce((select json_agg(json_build_object('form', g.form, 'score', g.score, 'total', g.total, 'at', g.created_at) order by g.created_at desc)
        from (select * from public.sb_gl_results where student_id = s.id and grade = s.grade order by created_at desc limit 4) g), '[]'::json) else null end,
    'family', (select count(*) from public.sb_family f where f.student_id = s.id),
    'sentences', (select count(*) from public.sb_sentences x where x.student_id = s.id));
  return res;
end $$;

revoke all on function public.sb_parent_token(text), public.sb_parent_tokens(), public.sb_parent_view(text), public.sb_new_parent_token() from public;
grant execute on function public.sb_parent_token(text), public.sb_parent_view(text) to anon, authenticated;
grant execute on function public.sb_parent_tokens() to authenticated;
select 'Parent links ready' as result;
