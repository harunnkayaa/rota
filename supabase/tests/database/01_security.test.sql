-- Security and data-integrity tests for the core schema.
-- Run with: supabase test db
--
-- Two users, A (owner) and B (someone else). Everything B tries against A's
-- data must fail or see nothing; A's own data must follow the domain rules.

begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

-- ---------------------------------------------------------------------------
-- Setup (as the database owner, RLS bypassed)
-- ---------------------------------------------------------------------------

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

insert into public.daily_allocations
  (id, user_id, goal_period_id, target_date, allocated_value)
values
  ('40000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-00000000000a',
   '30000000-0000-0000-0000-000000000001', '2026-09-28', 120);

insert into public.progress_entries
  (id, user_id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
values
  ('50000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-00000000000a',
   '30000000-0000-0000-0000-000000000001',
   90, 'manual', '2026-09-28 09:00+00', '2026-09-28', 'e1');

-- ---------------------------------------------------------------------------
-- As B: A's data is invisible and untouchable
-- ---------------------------------------------------------------------------

set local role authenticated;
set local "request.jwt.claims" to
  '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';

select is(
  (select count(*)::int from public.goal_periods), 0,
  'B cannot see A''s goal periods'
);
select is(
  (select count(*)::int from public.progress_entries), 0,
  'B cannot see A''s progress'
);

select results_eq(
  $$ with changed as (
       update public.goal_periods set target_value = 1 returning 1
     ) select count(*)::int from changed $$,
  $$ values (0) $$,
  'B cannot change A''s target'
);

select results_eq(
  $$ with removed as (
       delete from public.categories returning 1
     ) select count(*)::int from removed $$,
  $$ values (0) $$,
  'B cannot delete A''s category'
);

select throws_ok(
  $$ insert into public.progress_entries
       (id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-0000000000b1',
        '30000000-0000-0000-0000-000000000001',
        60, 'manual', now(), '2026-09-28', 'b1') $$,
  '23503',
  null,
  'B cannot attach progress to A''s period by guessing its id (IDOR)'
);

select throws_ok(
  $$ insert into public.progress_entries
       (id, user_id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-0000000000b2',
        '00000000-0000-0000-0000-00000000000a',
        '30000000-0000-0000-0000-000000000001',
        60, 'manual', now(), '2026-09-28', 'b2') $$,
  '42501',
  null,
  'B cannot write rows in A''s name'
);

-- ---------------------------------------------------------------------------
-- As A: own data works, domain rules hold
-- ---------------------------------------------------------------------------

set local "request.jwt.claims" to
  '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select is(
  (select count(*)::int from public.goal_periods), 1,
  'A sees own period'
);

select lives_ok(
  $$ insert into public.progress_entries
       (id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-000000000002',
        '30000000-0000-0000-0000-000000000001',
        30, 'manual', now(), '2026-09-29', 'e2') $$,
  'A adds progress; user_id defaults to the signed-in user'
);

select throws_ok(
  $$ insert into public.progress_entries
       (id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-000000000003',
        '30000000-0000-0000-0000-000000000001',
        30, 'manual', now(), '2026-09-29', 'e2') $$,
  '23505',
  null,
  'the same idempotency key is stored once (offline retry)'
);

select throws_ok(
  $$ insert into public.progress_entries
       (id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-000000000004',
        '30000000-0000-0000-0000-000000000001',
        30, 'manual', now(), '2026-10-05', 'e4') $$,
  '23514',
  null,
  'progress outside the period''s days is refused'
);

select throws_ok(
  $$ insert into public.progress_entries
       (id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-000000000005',
        '30000000-0000-0000-0000-000000000001',
        -30, 'manual', now(), '2026-09-29', 'e5') $$,
  '23514',
  null,
  'only adjustments may be negative'
);

select throws_ok(
  $$ update public.progress_entries set value_delta = 999 $$,
  '42501',
  null,
  'progress is append-only: no updates'
);

select throws_ok(
  $$ delete from public.progress_entries $$,
  '42501',
  null,
  'progress is append-only: no deletes'
);

select throws_ok(
  $$ insert into public.goal_templates
       (id, category_id, title, goal_type, measurement_type)
     values
       ('20000000-0000-0000-0000-000000000009',
        '10000000-0000-0000-0000-000000000001',
        'İlaç', 'flexibleQuota', 'dose') $$,
  '23514',
  null,
  'medication can never be a movable quota'
);

update public.daily_allocations set allocated_value = 180
  where id = '40000000-0000-0000-0000-000000000001';
select is(
  (select version from public.daily_allocations
    where id = '40000000-0000-0000-0000-000000000001'),
  2,
  'every edit bumps the version (conflict detection)'
);

insert into public.period_snapshots (period_id, snapshot_json, closed_at)
  values ('30000000-0000-0000-0000-000000000001', '{"achieved": 120}', now());

select throws_ok(
  $$ update public.period_snapshots set snapshot_json = '{"achieved": 600}' $$,
  '42501',
  null,
  'a closed week''s result cannot be rewritten'
);

select lives_ok(
  $$ update public.period_snapshots set reviewed_at = now() $$,
  'a snapshot can be marked as reviewed'
);

update public.goal_periods set closed_at = now()
  where id = '30000000-0000-0000-0000-000000000001';
select throws_ok(
  $$ insert into public.progress_entries
       (id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-000000000006',
        '30000000-0000-0000-0000-000000000001',
        30, 'manual', now(), '2026-09-30', 'e6') $$,
  '23514',
  null,
  'a closed period takes no new progress'
);

select lives_ok(
  $$ insert into public.progress_entries
       (id, goal_period_id, value_delta, source, occurred_at, local_date, idempotency_key)
     values
       ('50000000-0000-0000-0000-000000000007',
        '30000000-0000-0000-0000-000000000001',
        30, 'manual', '2026-09-28 08:00+00', '2026-09-28', 'e7') $$,
  'work done before the close is still accepted (late sync)'
);

-- ---------------------------------------------------------------------------
-- Signed out: nothing at all
-- ---------------------------------------------------------------------------

reset "request.jwt.claims";
set local role anon;

select throws_ok(
  $$ select * from public.goal_periods $$,
  '42501',
  null,
  'nothing is readable without signing in'
);

-- ---------------------------------------------------------------------------
-- Account deletion removes everything
-- ---------------------------------------------------------------------------

reset role;
delete from auth.users where id = '00000000-0000-0000-0000-00000000000a';

select is(
  (select
     (select count(*) from public.categories where user_id = '00000000-0000-0000-0000-00000000000a')
   + (select count(*) from public.goal_periods where user_id = '00000000-0000-0000-0000-00000000000a')
   + (select count(*) from public.progress_entries where user_id = '00000000-0000-0000-0000-00000000000a')
   + (select count(*) from public.period_snapshots where user_id = '00000000-0000-0000-0000-00000000000a'))::int,
  0,
  'deleting the account deletes all of its data'
);

select * from finish();
rollback;
