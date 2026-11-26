-- =====================================================================
--  SPELLING BEE — a word is SECURE (blue) only after it is spelt
--  correctly 3 TIMES IN A ROW. A mistake resets the count to 0.
--  Once secure, a word stays secure.
--  Everyone starts again from zero (words secured under the old
--  "2 correct" rule are checked again).
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
--  Safe to run more than once (it will NOT reset again after the first run).
-- =====================================================================

alter table public.progress add column if not exists runs   jsonb not null default '{}'::jsonb;  -- word -> correct in a row now
alter table public.progress add column if not exists secure jsonb not null default '{}'::jsonb;  -- word -> date it became secure

-- keeps "runs" and "secure" up to date every time an answer is recorded
create or replace function public.sb_progress_secure() returns trigger
language plpgsql as $$
declare nw jsonb := coalesce(to_jsonb(NEW.words), '{}'::jsonb); nt jsonb := coalesce(to_jsonb(NEW.tricky), '{}'::jsonb);
        ow jsonb := '{}'::jsonb; ot jsonb := '{}'::jsonb; e record; o int; r int;
        d text := to_char((now() at time zone 'Asia/Dubai')::date, 'YYYY-MM-DD');
begin
  if TG_OP = 'UPDATE' then ow := coalesce(to_jsonb(OLD.words), '{}'::jsonb); ot := coalesce(to_jsonb(OLD.tricky), '{}'::jsonb); end if;
  NEW.runs := coalesce(NEW.runs, '{}'::jsonb); NEW.secure := coalesce(NEW.secure, '{}'::jsonb);
  -- a new mistake on a word: back to 0 in a row
  for e in select key, value from jsonb_each_text(nt) loop
    o := case when coalesce(ot->>e.key, '') ~ '^\d+$' then (ot->>e.key)::int else 0 end;
    if e.value ~ '^\d+$' and e.value::int > o then NEW.runs := jsonb_set(NEW.runs, array[e.key], '0'::jsonb); end if;
  end loop;
  -- a new correct spelling: one more in a row (only single answers count, not bulk changes)
  for e in select key, value from jsonb_each_text(nw) loop
    o := case when coalesce(ow->>e.key, '') ~ '^\d+$' then (ow->>e.key)::int else 0 end;
    if e.value ~ '^\d+$' and e.value::int = o + 1 then
      r := case when coalesce(NEW.runs->>e.key, '') ~ '^\d+$' then (NEW.runs->>e.key)::int else 0 end + 1;
      NEW.runs := jsonb_set(NEW.runs, array[e.key], to_jsonb(r));
      if r >= 3 and not (NEW.secure ? e.key) then NEW.secure := jsonb_set(NEW.secure, array[e.key], to_jsonb(d)); end if;
    end if;
  end loop;
  return NEW;
end $$;
drop trigger if exists sb_progress_secure on public.progress;
create trigger sb_progress_secure before insert or update of words, tricky on public.progress
  for each row execute function public.sb_progress_secure();

-- the child's page asks for its secure words and runs
create or replace function public.sb_secure_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students; p public.progress;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  select * into p from public.progress where student_id = s.id;
  return json_build_object('secure', coalesce(p.secure, '{}'::jsonb), 'runs', coalesce(p.runs, '{}'::jsonb));
end $$;
revoke all on function public.sb_secure_mine(text) from public;
grant execute on function public.sb_secure_mine(text) to anon, authenticated;

-- 85% semi-final rule now counts SECURE words (3 in a row)
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
  select count(*) into n from public.progress p, jsonb_object_keys(coalesce(p.secure, '{}'::jsonb)) k where p.student_id = s.id;
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

-- the grown-up page counts SECURE words (3 in a row) too
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
    'secure', (select count(*) from jsonb_object_keys(coalesce(p->'secure','{}'::jsonb))),
    'tricky', coalesce((select json_agg(k) from (select e.key as k from jsonb_each_text(coalesce(p->'tricky','{}'::jsonb)) e
                 where not (coalesce(p->'secure','{}'::jsonb) ? e.key) order by e.value::int desc limit 12) t), '[]'::json),
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

select 'Secure = 3 in a row: ready' as result;
