# Rota

Personal planning app that links weekly goals to daily work: log 90 minutes
on Monday and see both "90/120 today" and "90/600 this week". Missed work is
shown, never silently moved; re-planning is always a proposal you approve.

Product and engineering rules: [CLAUDE.md](CLAUDE.md).
Defaults for undecided product questions: [docs/product/open-decisions.md](docs/product/open-decisions.md).

## Status

Phase 0 (domain + planning engine) and the Phase 1 local slice are done.
Data is **in memory only** — it disappears on reload. Supabase sync,
focus timer and notifications are next.

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
