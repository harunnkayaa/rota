-- time_blocks: the day's schedule ("09:00–11:00 Rota MVP", "Mola").
--
-- A block says *when*; how much of a goal is planned for the day stays in
-- daily_allocations, and work done stays in progress_entries. Mirrors
-- blockToRow in lib/features/planning/data/planner_json.dart.

create table public.time_blocks (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  block_date date not null,
  -- Minutes since local midnight; end exclusive, never past 24:00.
  start_minute integer not null
    check (start_minute >= 0 and start_minute < 1440),
  end_minute integer not null
    check (end_minute > start_minute and end_minute <= 1440),
  kind text not null check (kind in ('goal', 'rest', 'other')),
  goal_period_id uuid,
  title text check (title is null or char_length(title) between 1 and 200),
  remind boolean not null default false,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Exactly the goal blocks point to a goal period; "other" needs a name.
  check ((kind = 'goal') = (goal_period_id is not null)),
  check (kind <> 'other' or title is not null),
  -- (id, user_id): a block can never point to another user's goal (IDOR).
  -- A null goal_period_id (breaks, other) skips the check.
  foreign key (goal_period_id, user_id)
    references public.goal_periods (id, user_id) on delete cascade
);

create index time_blocks_user_date on public.time_blocks (user_id, block_date);

create trigger touch before update on public.time_blocks
  for each row execute function public.touch_updated_at();

alter table public.time_blocks enable row level security;

create policy "own rows" on public.time_blocks
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Nothing is readable without signing in.
revoke all on public.time_blocks from anon;
