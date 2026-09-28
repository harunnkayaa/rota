# Notification rules

Agreed with the user on 2026-09-26; implemented on 2026-09-28 as iOS local
notifications (`lib/features/reminders/`). This file is the contract.

## 1. Always talk about the time not yet worked

Every goal reminder is based on the **remaining** amount, never on the
original plan:

| Situation | Remaining used | Example text (open mode) |
|-----------|----------------|--------------------------|
| Today's plan partly done | `todayRemaining` = today's plan − today's work | "Rota MVP: bugün 1 sa 30 dk kaldı." |
| Today's plan fully done | 0 → **no reminder** | — |
| Plan changed during the day | recomputed from the new plan | Plan raised 2 → 3 sa, 1 sa done → "2 sa kaldı." |
| Weekly shortfall | `debt` (remaining target not covered by the plan) | "Bu hafta planın 1 sa 15 dk açıkta." |

Code: `GoalProgressView.todayRemaining`, `TodaySummary.remainingMinutes`,
`GoalProgressView.debt` in
`lib/features/planning/presentation/planner_controller.dart`.

Consequences:

- A reminder is computed at **delivery time** (or re-scheduled whenever
  progress or the plan changes), so it never mentions minutes that were
  already worked.
- Logging progress or editing the plan cancels / reschedules the pending
  reminder for that goal and day.
- The dedupe key includes the day: `{goal_period_id}:{local_date}:{type}`;
  a changed remaining amount replaces the pending reminder, it does not add
  a second one.

## 2. From CLAUDE.md §11 (unchanged)

- Quiet hours delay non-critical reminders.
- Daily notification budget.
- Sensitive goals (health, worship) use the hidden text:
  "Planlanmış kişisel hatırlatıcın var."
- Fixed-time critical reminders (medication) are about the scheduled time,
  not a remaining amount, and never suggest a make-up dose.
