-- time_blocks: own rows only, no attaching to someone else's goal, and the
-- same shape rules as the app (lib/features/schedule/domain/time_block.dart).

begin;
create extension if not exists pgtap with schema extensions;
-- The cloud test login does not inherit postgres rights; switch explicitly.
set local role postgres;
set local search_path = public, extensions;
select plan(12);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');

insert into public.categories (id, user_id, name, icon_key) values
  ('10000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-00000000000a', 'Proje', 'code');
insert into public.goal_templates
  (id, user_id, category_id, title, goal_type, measurement_type, default_target_value)
values
  ('20000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-00000000000a',
   '10000000-0000-0000-0000-000000000001',
   'Rota MVP', 'flexibleQuota', 'durationMinutes', 600);
insert into public.goal_periods
  (id, user_id, goal_template_id, period_type, start_date, end_date_exclusive, target_value)
values
  ('30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-00000000000a',
   '20000000-0000-0000-0000-000000000001',
   'calendarWeek', '2026-09-28', '2026-10-05', 600);

-- ---------------------------------------------------------------------------
-- As A: the day's plan follows the rules
-- ---------------------------------------------------------------------------
set local role authenticated;
set local "request.jwt.claims" to
  '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select lives_ok(
  $$ insert into public.time_blocks
       (id, block_date, start_minute, end_minute, kind, goal_period_id)
     values ('60000000-0000-0000-0000-000000000001', '2026-09-30',
             540, 660, 'goal', '30000000-0000-0000-0000-000000000001') $$,
  'A plans 09:00–11:00 on their goal'
);
select lives_ok(
  $$ insert into public.time_blocks
       (id, block_date, start_minute, end_minute, kind)
     values ('60000000-0000-0000-0000-000000000002', '2026-09-30',
             660, 675, 'rest') $$,
  'A adds a break without a goal'
);
select throws_ok(
  $$ insert into public.time_blocks
       (id, block_date, start_minute, end_minute, kind)
     values ('60000000-0000-0000-0000-000000000003', '2026-09-30',
             700, 690, 'rest') $$,
  '23514', null,
  'a block cannot end before it starts'
);
select throws_ok(
  $$ insert into public.time_blocks
       (id, block_date, start_minute, end_minute, kind)
     values ('60000000-0000-0000-0000-000000000004', '2026-09-30',
             1380, 1500, 'rest') $$,
  '23514', null,
  'a block cannot run into the next day'
);
select throws_ok(
  $$ insert into public.time_blocks
       (id, block_date, start_minute, end_minute, kind)
     values ('60000000-0000-0000-0000-000000000005', '2026-09-30',
             720, 780, 'goal') $$,
  '23514', null,
  'a goal block needs a goal'
);
select throws_ok(
  $$ insert into public.time_blocks
       (id, block_date, start_minute, end_minute, kind)
     values ('60000000-0000-0000-0000-000000000006', '2026-09-30',
             720, 780, 'other') $$,
  '23514', null,
  'an "other" block needs a name'
);
select lives_ok(
  $$ update public.time_blocks set start_minute = 600
     where id = '60000000-0000-0000-0000-000000000001' $$,
  'A moves their own block'
);

-- ---------------------------------------------------------------------------
-- As B: A's schedule is invisible and untouchable
-- ---------------------------------------------------------------------------
set local "request.jwt.claims" to
  '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';

select is(
  (select count(*)::int from public.time_blocks), 0,
  'B sees none of A''s blocks'
);
select throws_ok(
  $$ insert into public.time_blocks
       (id, block_date, start_minute, end_minute, kind, goal_period_id)
     values ('60000000-0000-0000-0000-000000000007', '2026-09-30',
             540, 600, 'goal', '30000000-0000-0000-0000-000000000001') $$,
  '23503', null,
  'B cannot attach a block to A''s goal, even with its id (IDOR)'
);
select results_eq(
  $$ with changed as (
       delete from public.time_blocks
       where id = '60000000-0000-0000-0000-000000000002' returning 1)
     select count(*)::int from changed $$,
  $$ values (0) $$,
  'B cannot delete A''s block'
);

set local role anon;
select throws_ok(
  $$ select * from public.time_blocks $$,
  '42501', null,
  'signed out: no access at all'
);

-- ---------------------------------------------------------------------------
-- Removing the goal week removes its blocks, not the breaks
-- ---------------------------------------------------------------------------
set local role postgres;
delete from public.goal_periods
  where id = '30000000-0000-0000-0000-000000000001';
select results_eq(
  $$ select kind from public.time_blocks
     where user_id = '00000000-0000-0000-0000-00000000000a' $$,
  $$ values ('rest') $$,
  'goal blocks go with their week; the break stays'
);

select * from finish();
rollback;
