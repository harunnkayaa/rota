# Rota

Personal planning app that links weekly goals to daily work: log 90 minutes
on Monday and see both "90/120 today" and "90/600 this week". Missed work is
shown, never silently moved; re-planning is always a proposal you approve.

Product and engineering rules: [CLAUDE.md](CLAUDE.md).
Defaults for undecided product questions: [docs/product/open-decisions.md](docs/product/open-decisions.md).
Where we left off and what is next: [docs/PROGRESS.md](docs/PROGRESS.md).

## Status

Phase 0 (domain + planning engine) and Phase 1 (local vertical slice) are
done. Data is saved on the device (iOS: NSUserDefaults, web: localStorage)
via `shared_preferences`; it is not synced between devices yet. Supabase
sync, focus timer and notifications are next.

## Run

```bash
flutter run -d chrome          # web
flutter run -d "iPhone 17 Pro" # iOS simulator (any installed simulator name)
```

## Check

```bash
dart format lib test
flutter analyze
flutter test
```

## Layout

```text
lib/
  app/            app shell, theme, localization (ARB + formatters)
  core/time/      LocalDate, PeriodRange, Clock
  features/
    categories/   GoalCategory
    goals/        Goal, GoalPeriod, DailyAllocation, ProgressEntry, create form
    planning/     planning engine (pure Dart), controller, week screen
    today/        today screen, goal card, add-progress sheet
  shared/widgets/ small reusable widgets
test/
  unit/           domain + controller
  widget/         end-to-end UI flows
```
