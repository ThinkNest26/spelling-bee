-- UNDO for setup-security.sql: lets the functions be called without signing in again.

grant execute on function public.admin_overview() to anon;
grant execute on function public.admin_request_done(bigint) to anon;
grant execute on function public.admin_set_limit(text, integer) to anon;
grant execute on function public.admin_set_plan(uuid, text, date) to anon;
grant execute on function public.admin_set_price(text, integer, text, jsonb) to anon;
grant execute on function public.mq_admin_interest(bigint, text) to anon;
grant execute on function public.mq_admin_overview() to anon;
grant execute on function public.mq_admin_report_status(text, text) to anon;
grant execute on function public.mq_admin_reports() to anon;
grant execute on function public.mq_admin_request_done(bigint) to anon;
grant execute on function public.mq_admin_set_plan(uuid, text, date) to anon;
grant execute on function public.mq_admin_set_price(text, integer, text, jsonb) to anon;
grant execute on function public.create_school(text, text, text, text, text) to anon;
grant execute on function public.mq_create_school(text, text, text, text, text) to anon;
grant execute on function public.request_plan(text, text) to anon;
grant execute on function public.mq_request_plan(text, text) to anon;
grant execute on function public.school_set_slug(text) to anon;
grant execute on function public.my_school_info() to anon;
grant execute on function public.teacher_words() to anon;
grant execute on function public.sb_is_organiser() to anon;
grant execute on function public.sq_add_students(uuid, text[]) to anon;
grant execute on function public.sq_new_code_for(uuid) to anon;
