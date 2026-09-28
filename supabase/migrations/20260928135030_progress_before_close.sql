-- A closed period takes no new work — but work done *before* it closed
-- (logged offline, or synced from a device for the first time) is history
-- and must be accepted, or the user's input would be lost.

create or replace function public.check_progress_entry()
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
  if p.closed_at is not null and new.occurred_at >= p.closed_at then
    raise exception 'period % is closed', p.id using errcode = 'check_violation';
  end if;
  return new;
end;
$$;
