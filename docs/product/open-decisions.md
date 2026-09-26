# Open product decisions

Decisions taken as defaults so work could continue. Each can be revisited;
the code location that depends on it is listed.

| # | Question | Current default | Where |
|---|----------|-----------------|-------|
| 1 | Is daily progress counted by entry date or by an explicit allocation link? | **By `local_date`.** An entry counts for the day it was made; it cannot be attached to the wrong day. `daily_allocation_id` from CLAUDE.md §9.6 is not used. (Approved by the user.) | `planning/domain/progress_calculator.dart` |
| 2 | What happens to an offline entry that syncs after its period closed? | **Rejected** for now (`ProgressRejection.periodClosed`). Proposed: accept it, keep the snapshot unchanged, show it as a "late entry" in reports. | `validateNewEntry` |
| 3 | In reports, is "planned" the first plan or the plan after redistribution? | Not decided; reports are not built yet. Proposed: show both (plan baseline). | — |
| 4 | Do non-duration goals (pages, count) use up daily capacity? | **No.** Only `durationMinutes` consumes capacity. | `MeasurementType.consumesCapacity` |
| 5 | Daily capacity | **240 min/day** for everyone until settings exist. | `defaultDailyCapacityMinutes` |
| 6 | Which timezone defines "today"? | **Device timezone** in Phase 1. The profile timezone (IANA, default `Europe/Istanbul`) takes over in Phase 2. | `SystemClock` |
| 7 | Min/max length of a custom period | No limit beyond `start < end`. | `PeriodRange` |
| 8 | Does redistribution include today? | **No by default**; the user can switch it on in the sheet. | `remainingDays` |
| 9 | Local storage | **`shared_preferences`**, whole state as one versioned JSON document (`schema_version`). Unreadable data is never overwritten; the app shows an error with retry. Not encrypted — revisit before syncing sensitive categories. `drift` is the candidate if data grows or the offline queue needs queries. | `planning/data/` |
| 10 | Can past days' plans be edited? | **No.** Today and later days are editable; past days are shown locked with done/planned, so "planned vs. done" stays honest. | `applyPlanChanges` |
| 11 | What does "over-planned" mean after a missed day? | Compared on what is **left**: plan from today on vs. remaining target. Making up a short Monday on Tuesday is "covered", not "over target". | `remainingPlanned`, `GoalProgressView.surplus` |
