-- Rota core schema.
--
-- Mirrors the app's storage model (lib/features/planning/data/planner_json.dart);
-- column names are the same as the JSON keys.
--
-- Security model:
-- * Every table has user_id and Row Level Security: a user sees and changes
--   only their own rows.
-- * Foreign keys ignore RLS, so every child row points to its parent with
--   (id, user_id). A row can therefore never be attached to another user's
--   goal, even with a guessed id (IDOR).
-- * Deleting the auth user deletes all of their data (on delete cascade).

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  -- Optimistic concurrency: every change bumps the version, so a client
  -- editing an older copy can detect the conflict instead of overwriting.
  if tg_op = 'UPDATE' and to_jsonb(new) ? 'version' then
    new := jsonb_populate_record(
      new,
      jsonb_build_object('version', (to_jsonb(old) ->> 'version')::int + 1)
    );
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles: one row per user, holds settings
-- ---------------------------------------------------------------------------

create table public.profiles (
  user_id uuid primary key default auth.uid()
    references auth.users (id) on delete cascade,
  timezone text not null default 'Europe/Istanbul',
  locale text not null default 'tr',
  week_start_day smallint not null default 1
    check (week_start_day between 1 and 7),
  daily_capacity_minutes integer not null default 240
    check (daily_capacity_minutes between 0 and 1440),
  weekday_capacity_minutes jsonb not null default '{}'::jsonb,
  reminders jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------

create table public.categories (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null check (length(btrim(name)) > 0),
  icon_key text not null,
  preset text,
  is_sensitive boolean not null default false,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

-- ---------------------------------------------------------------------------
-- goal_templates: the reusable definition of a goal
-- ---------------------------------------------------------------------------

create table public.goal_templates (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  category_id uuid not null,
  title text not null check (length(btrim(title)) > 0),
  goal_type text not null check (
    goal_type in ('flexibleQuota', 'recurringRoutine', 'fixedTimeCritical', 'deadline')
  ),
  measurement_type text not null check (
    measurement_type in (
      'durationMinutes', 'count', 'pages', 'boolean', 'sessions', 'dose', 'customNumeric'
    )
  ),
  default_target_value integer check (default_target_value > 0),
  is_sensitive boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id),
  foreign key (category_id, user_id)
    references public.categories (id, user_id) on delete restrict,
  -- Medication is a fixed-time routine, never a movable quota.
  check (measurement_type <> 'dose' or goal_type = 'fixedTimeCritical')
);

-- ---------------------------------------------------------------------------
-- goal_periods: one instance of a goal over dates [start, end)
-- ---------------------------------------------------------------------------

create table public.goal_periods (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  goal_template_id uuid not null,
  period_type text not null check (
    period_type in ('calendarWeek', 'rolling7Days', 'custom', 'daily')
  ),
  start_date date not null,
  end_date_exclusive date not null,
  target_value integer not null check (target_value > 0),
  carryover_from_period_id uuid unique,
  closed_at timestamptz,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id),
  foreign key (goal_template_id, user_id)
    references public.goal_templates (id, user_id) on delete cascade,
  foreign key (carryover_from_period_id, user_id)
    references public.goal_periods (id, user_id) on delete set null (carryover_from_period_id),
  check (start_date < end_date_exclusive),
  check (
    period_type not in ('calendarWeek', 'rolling7Days')
    or end_date_exclusive - start_date = 7
  ),
  check (period_type <> 'daily' or end_date_exclusive - start_date = 1)
);

-- ---------------------------------------------------------------------------
-- daily_allocations: the part of a period planned for one day
-- ---------------------------------------------------------------------------

create table public.daily_allocations (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  goal_period_id uuid not null,
  target_date date not null,
  allocated_value integer not null check (allocated_value >= 0),
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (goal_period_id, target_date),
  foreign key (goal_period_id, user_id)
    references public.goal_periods (id, user_id) on delete cascade
);

-- ---------------------------------------------------------------------------
-- progress_entries: the single source of truth for work done (append-only)
-- ---------------------------------------------------------------------------

create table public.progress_entries (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  goal_period_id uuid not null,
  value_delta integer not null check (value_delta <> 0),
  source text not null check (
    source in ('manual', 'focusTimer', 'imported', 'adjustment')
  ),
  occurred_at timestamptz not null,
  local_date date not null,
  idempotency_key text not null,
  note text,
  created_at timestamptz not null default now(),
  -- A retried offline sync sends the same key again: stored once.
  unique (user_id, idempotency_key),
  unique (id, user_id),
  foreign key (goal_period_id, user_id)
    references public.goal_periods (id, user_id) on delete cascade,
  check (value_delta > 0 or source = 'adjustment')
);

-- The day must be inside the period, and a closed period takes no new work.
create function public.check_progress_entry()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  p public.goal_periods;
begin
  select * into p from public.goal_periods where id = new.goal_period_id;
  if new.local_date < p.start_date or new.local_date >= p.end_date_exclusive then
    raise exception 'local_date % is outside period %', new.local_date, p.id
      using errcode = 'check_violation';
  end if;
  if p.closed_at is not null then
    raise exception 'period % is closed', p.id using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger progress_entry_rules
  before insert on public.progress_entries
  for each row execute function public.check_progress_entry();

-- ---------------------------------------------------------------------------
-- period_snapshots: frozen results of closed periods
-- ---------------------------------------------------------------------------

create table public.period_snapshots (
  period_id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  snapshot_json jsonb not null,
  closed_at timestamptz not null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (period_id, user_id)
    references public.goal_periods (id, user_id) on delete cascade
);

-- ---------------------------------------------------------------------------
-- focus_sessions
-- ---------------------------------------------------------------------------

create table public.focus_sessions (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  goal_period_id uuid not null,
  started_at timestamptz not null,
  paused_at timestamptz,
  paused_seconds integer not null default 0 check (paused_seconds >= 0),
  status text not null default 'running' check (
    status in ('running', 'paused', 'completed', 'cancelled')
  ),
  progress_entry_id uuid,
  updated_at timestamptz not null default now(),
  foreign key (goal_period_id, user_id)
    references public.goal_periods (id, user_id) on delete cascade,
  foreign key (progress_entry_id, user_id)
    references public.progress_entries (id, user_id)
    on delete set null (progress_entry_id)
);

-- One timer at a time per user.
create unique index focus_sessions_one_active
  on public.focus_sessions (user_id)
  where status in ('running', 'paused');

-- ---------------------------------------------------------------------------
-- Indexes for the queries the app makes (by user, by period, by day)
-- ---------------------------------------------------------------------------

create index categories_user on public.categories (user_id);
create index goal_templates_user on public.goal_templates (user_id);
create index goal_periods_user_dates
  on public.goal_periods (user_id, start_date, end_date_exclusive);
create index daily_allocations_user_date
  on public.daily_allocations (user_id, target_date);
create index progress_entries_period_day
  on public.progress_entries (goal_period_id, local_date);
create index progress_entries_user_day
  on public.progress_entries (user_id, local_date);

-- ---------------------------------------------------------------------------
-- updated_at / version triggers
-- ---------------------------------------------------------------------------

create trigger touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger touch before update on public.categories
  for each row execute function public.touch_updated_at();
create trigger touch before update on public.goal_templates
  for each row execute function public.touch_updated_at();
create trigger touch before update on public.goal_periods
  for each row execute function public.touch_updated_at();
create trigger touch before update on public.daily_allocations
  for each row execute function public.touch_updated_at();
create trigger touch before update on public.focus_sessions
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.goal_templates enable row level security;
alter table public.goal_periods enable row level security;
alter table public.daily_allocations enable row level security;
alter table public.progress_entries enable row level security;
alter table public.period_snapshots enable row level security;
alter table public.focus_sessions enable row level security;

-- Full access to own rows. `(select auth.uid())` is evaluated once per
-- query instead of once per row.
create policy "own rows" on public.profiles
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on public.categories
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on public.goal_templates
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on public.goal_periods
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on public.daily_allocations
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "own rows" on public.focus_sessions
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Progress is append-only: read and add, never change or delete. Mistakes
-- are corrected with a negative 'adjustment' entry.
create policy "read own" on public.progress_entries
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy "add own" on public.progress_entries
  for insert to authenticated
  with check (user_id = (select auth.uid()));
revoke update, delete on public.progress_entries from authenticated, anon;

-- Snapshots are frozen: read, add, and only mark as reviewed.
create policy "read own" on public.period_snapshots
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy "add own" on public.period_snapshots
  for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "mark reviewed" on public.period_snapshots
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
revoke update, delete on public.period_snapshots from authenticated, anon;
grant update (reviewed_at) on public.period_snapshots to authenticated;

-- Nothing is readable without signing in.
revoke all on all tables in schema public from anon;
