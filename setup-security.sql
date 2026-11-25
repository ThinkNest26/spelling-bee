-- Spelling Bee security tidy-up (Nov 2026)
-- Stops visitors who are NOT signed in from calling teacher and admin functions.
-- Children's code functions, the parent page and the public school page are not touched.
-- Teachers and admins (signed in) keep full access.

revoke execute on function public.admin_overview() from public, anon;
grant execute on function public.admin_overview() to authenticated;
revoke execute on function public.admin_request_done(bigint) from public, anon;
grant execute on function public.admin_request_done(bigint) to authenticated;
revoke execute on function public.admin_set_limit(text, integer) from public, anon;
grant execute on function public.admin_set_limit(text, integer) to authenticated;
revoke execute on function public.admin_set_plan(uuid, text, date) from public, anon;
grant execute on function public.admin_set_plan(uuid, text, date) to authenticated;
revoke execute on function public.admin_set_price(text, integer, text, jsonb) from public, anon;
grant execute on function public.admin_set_price(text, integer, text, jsonb) to authenticated;
revoke execute on function public.mq_admin_interest(bigint, text) from public, anon;
grant execute on function public.mq_admin_interest(bigint, text) to authenticated;
revoke execute on function public.mq_admin_overview() from public, anon;
grant execute on function public.mq_admin_overview() to authenticated;
revoke execute on function public.mq_admin_report_status(text, text) from public, anon;
grant execute on function public.mq_admin_report_status(text, text) to authenticated;
revoke execute on function public.mq_admin_reports() from public, anon;
grant execute on function public.mq_admin_reports() to authenticated;
revoke execute on function public.mq_admin_request_done(bigint) from public, anon;
grant execute on function public.mq_admin_request_done(bigint) to authenticated;
revoke execute on function public.mq_admin_set_plan(uuid, text, date) from public, anon;
grant execute on function public.mq_admin_set_plan(uuid, text, date) to authenticated;
revoke execute on function public.mq_admin_set_price(text, integer, text, jsonb) from public, anon;
grant execute on function public.mq_admin_set_price(text, integer, text, jsonb) to authenticated;
revoke execute on function public.create_school(text, text, text, text, text) from public, anon;
grant execute on function public.create_school(text, text, text, text, text) to authenticated;
revoke execute on function public.mq_create_school(text, text, text, text, text) from public, anon;
grant execute on function public.mq_create_school(text, text, text, text, text) to authenticated;
revoke execute on function public.request_plan(text, text) from public, anon;
grant execute on function public.request_plan(text, text) to authenticated;
revoke execute on function public.mq_request_plan(text, text) from public, anon;
grant execute on function public.mq_request_plan(text, text) to authenticated;
revoke execute on function public.school_set_slug(text) from public, anon;
grant execute on function public.school_set_slug(text) to authenticated;
revoke execute on function public.my_school_info() from public, anon;
grant execute on function public.my_school_info() to authenticated;
revoke execute on function public.teacher_words() from public, anon;
grant execute on function public.teacher_words() to authenticated;
revoke execute on function public.sb_is_organiser() from public, anon;
grant execute on function public.sb_is_organiser() to authenticated;
revoke execute on function public.sq_add_students(uuid, text[]) from public, anon;
grant execute on function public.sq_add_students(uuid, text[]) to authenticated;
revoke execute on function public.sq_new_code_for(uuid) from public, anon;
grant execute on function public.sq_new_code_for(uuid) to authenticated;
