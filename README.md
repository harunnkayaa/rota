<div align="center">

# 🧭 Rota

### Your personal growth roadmap

**Turn big career and life goals into weekly targets and realistic daily plans —
and stay on course when real life gets in the way.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?logo=apple&logoColor=white)
![Web](https://img.shields.io/badge/Web-4285F4?logo=googlechrome&logoColor=white)
![Tests](https://img.shields.io/badge/tests-126%20passing-2ea44f)
![Status](https://img.shields.io/badge/status-in%20development-orange)

</div>

---

## Why Rota?

Most planners answer *"what do I have to do?"*. The hard questions are different:

- *I'm job hunting, preparing for an exam, building a project and trying to stay healthy — **how do I split one week between all of it?***
- *I planned 4 hours on Monday and did 3. **What happens to the rest of my week?***
- *Am I planning more than I can actually do?*

Rota is built around those questions. It is not a to-do list — it is a **route**
from your goals to your days.

## ✨ What makes it different

| | |
|---|---|
| 🔗 **Weekly ↔ daily, connected** | Log 90 minutes on Monday and see both *90 / 120 today* and *90 / 600 this week*. One entry, counted once, everywhere. |
| 🗓️ **Your plan, day by day** | Put 4 hours on Monday, 2 on Tuesday, nothing on Sunday. Change any future day later from the Today or Week screen. |
| 🧮 **Honest about capacity** | A daily capacity model warns you *before* a day is overloaded. An unrealistic plan is never shown as success. |
| 🔁 **Missed time, re-planned — with your approval** | Fell short on Monday? Rota shows exactly how much is uncovered and proposes an explainable redistribution. Nothing moves silently. |
| ⚖️ **Make-up aware** | Add the missing hour to Tuesday and the gap simply closes — no "over target" nagging for catching up. |
| 🔒 **Different goals, different rules** | Flexible study hours can be moved; fixed-time routines like medication or prayer never are. Past days stay as history. |
| 🧘 **No guilt, no gamification** | Neutral language ("60 minutes not completed yet"), no red punishment screens, no points economy. |

## 🧠 How it works

```text
 Goal ─────────► Week period ─────────► Daily plan ─────────► Progress entries
 "Project"       600 min, 28 Sep–4 Oct   Mon 240 · Tue 120 …    Mon +180
                         │                                           │
                         └──────────── totals are always ◄───────────┘
                                       derived, never stored twice

 Remaining target − remaining plan = uncovered time  →  proposal  →  you approve
```

All planning rules live in a **pure Dart planning engine**, independent of the
UI and fully unit-tested: deterministic splitting (largest remainder, no lost
minutes), capacity checks, debt detection, redistribution, period close
snapshots and explicit carry-over.

## 🛠️ Tech

- **Flutter / Dart** — one codebase for iPhone and web, responsive layout
  (bottom bar on phones, side rail on desktop), light & dark themes
- **Feature-first architecture** — `domain` (pure Dart) · `data` · `presentation`
- **Local-first** — data saved on device with a versioned schema; unreadable
  data is never overwritten
- **Localization-ready** — all UI text via `gen-l10n` (Turkish first)
- **Accessibility** — screen-reader labels, Dynamic Type-safe layouts,
  reduce-motion aware animations, colour never the only signal

## 🗺️ Roadmap

- [x] Planning engine: progress, capacity, goal debt, redistribution, period close
- [x] Today & Week screens, per-day planning and editing
- [x] On-device persistence
- [ ] Sign-in and iPhone ↔ web sync (Supabase, PostgreSQL + RLS)
- [ ] Focus timer and offline-safe progress queue
- [ ] Smart reminders — always about the time *not yet worked*, with quiet hours and a daily budget
- [ ] Weekly reports: planned vs. done
- [ ] Interview & exam modes: plan backwards from a deadline

## 🚀 Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
git clone git@github.com:harunnkayaa/rota.git
cd rota
flutter pub get
flutter run -d chrome        # or pick an iOS simulator with: flutter devices
```

Run the checks:

```bash
flutter analyze && flutter test
```

<details>
<summary>Project structure</summary>

```text
lib/
  app/            shell, theme, localization
  core/time/      LocalDate, PeriodRange, Clock
  features/
    categories/   categories and their styles
    goals/        goals, periods, daily allocations, progress entries
    planning/     planning engine (pure Dart), storage, week screen, plan editor
    today/        today screen, goal card, add-progress sheet
  shared/widgets/ reusable UI pieces
test/
  unit/           planning engine, storage, controller
  widget/         end-to-end UI flows
docs/             product decisions, notification rules, progress notes
```

</details>

<details>
<summary>For contributors</summary>

- Product & engineering rules: [CLAUDE.md](CLAUDE.md)
- Current status and next steps: [docs/PROGRESS.md](docs/PROGRESS.md)
- Open product decisions: [docs/product/open-decisions.md](docs/product/open-decisions.md)

</details>
