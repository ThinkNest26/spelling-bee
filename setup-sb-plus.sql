-- =====================================================================
--  SPELLING BEE — smart review, weekly words, sentences, error patterns,
--  reading support and family challenges.
--  Paste ALL of this into Supabase -> SQL Editor -> New query -> Run.
--  Safe to run more than once.
-- =====================================================================

-- ---------- 1. Smart review of tricky words (1 day, 3 days, 7 days) ----------
create table if not exists public.sb_review (
  student_id uuid not null references public.students(id) on delete cascade,
  word       text not null,
  box        int  not null default 1,          -- 1, 2, 3 = reviewing; 4 = mastered
  streak     int  not null default 0,          -- right in a row on review days
  due        date not null,
  mastered   boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (student_id, word)
);
alter table public.sb_review enable row level security;
drop policy if exists sb_review_teacher on public.sb_review;
create policy sb_review_teacher on public.sb_review for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_review to authenticated;

create or replace function public.sb_x_today() returns date language sql stable as $$
  select (now() at time zone 'Asia/Dubai')::date
$$;

create or replace function public.sb_review_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return '[]'::json; end if;
  return coalesce((select json_agg(json_build_object('w', word, 'b', box, 's', streak, 'due', due, 'm', mastered,
      'u', (extract(epoch from updated_at) * 1000)::bigint))
    from public.sb_review where student_id = s.id), '[]'::json);
end $$;

-- a wrong answer puts the word in review for tomorrow; a right answer on a review day moves it on
create or replace function public.sb_review_mark(p_code text, p_word text, p_ok boolean) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; r public.sb_review; td date := public.sb_x_today(); w text := left(trim(coalesce(p_word,'')), 40);
begin
  s := public.sb_student(p_code);
  if s.id is null or w = '' then return null; end if;
  select * into r from public.sb_review where student_id = s.id and word = w;
  if not coalesce(p_ok, false) then
    insert into public.sb_review(student_id, word, box, streak, due, mastered, updated_at)
    values (s.id, w, 1, 0, td + 1, false, now())
    on conflict (student_id, word) do update set box = 1, streak = 0, due = td + 1, mastered = false, updated_at = now();
  elsif r.student_id is not null and not r.mastered and r.due <= td then
    if r.streak + 1 >= 3 then
      update public.sb_review set streak = 3, box = 4, mastered = true, updated_at = now() where student_id = s.id and word = w;
    else
      update public.sb_review set streak = r.streak + 1, box = r.streak + 2,
             due = td + case when r.streak + 1 = 1 then 3 else 7 end, updated_at = now()
       where student_id = s.id and word = w;
    end if;
  end if;
  return json_build_object('ok', true);
end $$;

-- the first time: words that are already tricky go into review today
create or replace function public.sb_review_seed(p_code text, p_words text[]) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; w text;
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  foreach w in array (coalesce(p_words, '{}'::text[]))[1:60] loop
    if length(trim(w)) between 1 and 40 then
      insert into public.sb_review(student_id, word, box, streak, due) values (s.id, trim(w), 1, 0, public.sb_x_today())
      on conflict do nothing;
    end if;
  end loop;
  return json_build_object('ok', true);
end $$;

-- ---------- 2. Mistakes (for error patterns) ----------
create table if not exists public.sb_mistakes (
  id         bigint generated always as identity primary key,
  student_id uuid not null references public.students(id) on delete cascade,
  word       text not null,
  typed      text not null,
  activity   text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists sb_mistakes_kid on public.sb_mistakes(student_id, created_at desc);
alter table public.sb_mistakes enable row level security;
drop policy if exists sb_mistakes_teacher on public.sb_mistakes;
create policy sb_mistakes_teacher on public.sb_mistakes for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_mistakes to authenticated;

create or replace function public.sb_mistake_add(p_code text, p_word text, p_typed text, p_activity text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null or length(trim(coalesce(p_word,''))) not between 1 and 40 or length(trim(coalesce(p_typed,''))) not between 1 and 60 then return null; end if;
  if (select count(*) from public.sb_mistakes where student_id = s.id and created_at > now() - interval '1 day') > 400 then return null; end if;
  insert into public.sb_mistakes(student_id, word, typed, activity)
  values (s.id, trim(p_word), trim(p_typed), left(coalesce(p_activity,''), 20));
  return json_build_object('ok', true);
end $$;

-- ---------- 3. Use it in a sentence ----------
create table if not exists public.sb_sentences (
  id         bigint generated always as identity primary key,
  student_id uuid not null references public.students(id) on delete cascade,
  word       text not null,
  sentence   text not null,
  created_at timestamptz not null default now()
);
create index if not exists sb_sentences_kid on public.sb_sentences(student_id, created_at desc);
alter table public.sb_sentences enable row level security;
drop policy if exists sb_sentences_teacher on public.sb_sentences;
create policy sb_sentences_teacher on public.sb_sentences for select to authenticated using (public.sb_kid_in_my_school(student_id));
drop policy if exists sb_sentences_teacher_del on public.sb_sentences;
create policy sb_sentences_teacher_del on public.sb_sentences for delete to authenticated using (public.sb_kid_in_my_school(student_id));
grant select, delete on public.sb_sentences to authenticated;

create or replace function public.sb_sentence_save(p_code text, p_word text, p_text text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; first boolean; give int := 0;
begin
  s := public.sb_student(p_code);
  if s.id is null or length(trim(coalesce(p_word,''))) not between 1 and 40 or length(trim(coalesce(p_text,''))) not between 3 and 300 then return null; end if;
  if (select count(*) from public.sb_sentences where student_id = s.id and created_at > now() - interval '1 day') >= 40 then return json_build_object('error','limit'); end if;
  first := not exists (select 1 from public.sb_sentences where student_id = s.id and lower(word) = lower(trim(p_word)));
  insert into public.sb_sentences(student_id, word, sentence) values (s.id, trim(p_word), trim(p_text));
  if first then
    give := 2;
    insert into public.progress(student_id) values (s.id) on conflict do nothing;
    update public.progress set stars = stars + give where student_id = s.id;
  end if;
  return json_build_object('give', give);
end $$;

create or replace function public.sb_sentence_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return '[]'::json; end if;
  return coalesce((select json_agg(json_build_object('w', word, 't', sentence, 'at', created_at) order by created_at desc)
    from (select * from public.sb_sentences where student_id = s.id order by created_at desc limit 200) x), '[]'::json);
end $$;

-- ---------- 4. Reading support (set by the teacher for each child) ----------
create table if not exists public.sb_support (
  student_id uuid primary key references public.students(id) on delete cascade,
  on_at      timestamptz not null default now()
);
alter table public.sb_support enable row level security;
drop policy if exists sb_support_teacher on public.sb_support;
create policy sb_support_teacher on public.sb_support for all to authenticated
  using (public.sb_kid_in_my_school(student_id)) with check (public.sb_kid_in_my_school(student_id));
grant select, insert, delete on public.sb_support to authenticated;

create or replace function public.sb_support_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  return json_build_object('on', s.id is not null and exists (select 1 from public.sb_support where student_id = s.id));
end $$;

-- ---------- 5. Weekly words: pre-test and post-test ----------
create table if not exists public.sb_weekly (
  id         bigint generated always as identity primary key,
  school_id  uuid not null default public.my_school() references public.schools(id) on delete cascade,
  grade      int  not null check (grade between 0 and 5),
  class_name text not null default '',        -- '' = every class in the grade
  title      text not null default '',
  words      text[] not null,
  challenge  text[] not null default '{}',
  post_from  date not null,
  created_at timestamptz not null default now()
);
alter table public.sb_weekly enable row level security;
drop policy if exists sb_weekly_teacher on public.sb_weekly;
create policy sb_weekly_teacher on public.sb_weekly for all to authenticated
  using (school_id = public.my_school()) with check (school_id = public.my_school());
grant select, insert, update, delete on public.sb_weekly to authenticated;

create table if not exists public.sb_weekly_results (
  id         bigint generated always as identity primary key,
  weekly_id  bigint not null references public.sb_weekly(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  kind       text not null check (kind in ('pre','post')),
  score      int  not null,
  total      int  not null,
  answers    jsonb not null default '{}'::jsonb,   -- word -> what the child typed
  challenge  boolean not null default false,
  created_at timestamptz not null default now(),
  unique (weekly_id, student_id, kind)
);
alter table public.sb_weekly_results enable row level security;
drop policy if exists sb_weekly_results_teacher on public.sb_weekly_results;
create policy sb_weekly_results_teacher on public.sb_weekly_results for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_weekly_results to authenticated;

create or replace function public.sb_weekly_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return '[]'::json; end if;
  return coalesce((select json_agg(json_build_object('id', w.id, 'title', w.title, 'words', w.words, 'challenge', w.challenge,
      'post_from', w.post_from, 'today', public.sb_x_today(),
      'pre',  (select json_build_object('score', r.score, 'total', r.total, 'answers', r.answers, 'challenge', r.challenge) from public.sb_weekly_results r where r.weekly_id = w.id and r.student_id = s.id and r.kind = 'pre'),
      'post', (select json_build_object('score', r.score, 'total', r.total, 'answers', r.answers, 'challenge', r.challenge) from public.sb_weekly_results r where r.weekly_id = w.id and r.student_id = s.id and r.kind = 'post'))
      order by w.created_at desc)
    from (select * from public.sb_weekly
           where school_id = s.school_id and grade = s.grade
             and (class_name = '' or lower(class_name) = lower(s.class_name))
             and post_from >= public.sb_x_today() - 14
           order by created_at desc limit 3) w), '[]'::json);
end $$;

create or replace function public.sb_weekly_save(p_code text, p_id bigint, p_kind text, p_score int, p_total int,
  p_answers jsonb, p_challenge boolean) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; w public.sb_weekly; give int := 0;
begin
  s := public.sb_student(p_code);
  if s.id is null or p_kind not in ('pre','post') or p_total is null or p_total < 1 or p_total > 60 or p_score < 0 or p_score > p_total then return null; end if;
  select * into w from public.sb_weekly where id = p_id and school_id = s.school_id and grade = s.grade;
  if w.id is null then return json_build_object('error','missing'); end if;
  if exists (select 1 from public.sb_weekly_results where weekly_id = p_id and student_id = s.id and kind = p_kind) then
    return json_build_object('error','done'); end if;
  if p_kind = 'post' then
    if not exists (select 1 from public.sb_weekly_results where weekly_id = p_id and student_id = s.id and kind = 'pre') then return json_build_object('error','pre'); end if;
    if w.post_from > public.sb_x_today() then return json_build_object('error','early'); end if;
    give := 5;
  end if;
  insert into public.sb_weekly_results(weekly_id, student_id, kind, score, total, answers, challenge)
  values (p_id, s.id, p_kind, p_score, p_total, coalesce(p_answers,'{}'::jsonb), coalesce(p_challenge,false));
  if give > 0 then
    insert into public.progress(student_id) values (s.id) on conflict do nothing;
    update public.progress set stars = stars + give where student_id = s.id;
  end if;
  return json_build_object('give', give);
end $$;

-- ---------- 6. Family challenge (one a week) ----------
create table if not exists public.sb_family (
  student_id uuid not null references public.students(id) on delete cascade,
  week       date not null,                  -- the Monday of the week
  note       text not null default '',
  grownup    text not null default '',
  done_at    timestamptz not null default now(),
  primary key (student_id, week)
);
alter table public.sb_family enable row level security;
drop policy if exists sb_family_teacher on public.sb_family;
create policy sb_family_teacher on public.sb_family for select to authenticated using (public.sb_kid_in_my_school(student_id));
grant select on public.sb_family to authenticated;

create or replace function public.sb_x_week_start() returns date language sql stable as $$
  select public.sb_x_today() - ((extract(isodow from public.sb_x_today())::int) - 1)
$$;

create or replace function public.sb_family_done(p_code text, p_note text, p_grownup text) returns json
language plpgsql security definer set search_path = public as $$
declare s public.students; wk date := public.sb_x_week_start();
begin
  s := public.sb_student(p_code);
  if s.id is null then return null; end if;
  if exists (select 1 from public.sb_family where student_id = s.id and week = wk) then return json_build_object('give', 0); end if;
  insert into public.sb_family(student_id, week, note, grownup) values (s.id, wk, left(coalesce(p_note,''), 300), left(coalesce(p_grownup,''), 60));
  insert into public.progress(student_id) values (s.id) on conflict do nothing;
  update public.progress set stars = stars + 5 where student_id = s.id;
  return json_build_object('give', 5);
end $$;

create or replace function public.sb_family_mine(p_code text) returns json
language plpgsql stable security definer set search_path = public as $$
declare s public.students;
begin
  s := public.sb_student(p_code);
  if s.id is null then return '[]'::json; end if;
  return coalesce((select json_agg(json_build_object('week', week, 'note', note) order by week desc)
    from public.sb_family where student_id = s.id), '[]'::json);
end $$;

-- ---------- permissions ----------
revoke all on function public.sb_review_mine(text), public.sb_review_mark(text,text,boolean), public.sb_review_seed(text,text[]),
  public.sb_mistake_add(text,text,text,text), public.sb_sentence_save(text,text,text), public.sb_sentence_mine(text),
  public.sb_support_mine(text), public.sb_weekly_mine(text), public.sb_weekly_save(text,bigint,text,int,int,jsonb,boolean),
  public.sb_family_done(text,text,text), public.sb_family_mine(text) from public;
grant execute on function public.sb_review_mine(text), public.sb_review_mark(text,text,boolean), public.sb_review_seed(text,text[]),
  public.sb_mistake_add(text,text,text,text), public.sb_sentence_save(text,text,text), public.sb_sentence_mine(text),
  public.sb_support_mine(text), public.sb_weekly_mine(text), public.sb_weekly_save(text,bigint,text,int,int,jsonb,boolean),
  public.sb_family_done(text,text,text), public.sb_family_mine(text) to anon, authenticated;
grant execute on function public.sb_x_today(), public.sb_x_week_start() to anon, authenticated;
select 'Spelling Bee extras ready' as result;
