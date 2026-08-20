# AGENTS.md — Guide for AI agents

Mandatory instructions when working on **Administradores Diaz PH v2** (`administradores-diaz-ph-v2`). Read this before editing code.

## What this project is

Flutter app (mobile/web/desktop) for Propiedad Horizontal (condo/building) management. Backend: Firebase Auth, Firestore, Storage, FCM.

- This repo is a **pre-production v2**. Production runs on a different project.
- The product goal is a **multi-tenant platform** for multiple property-management companies, not only Administradores Diaz PH.
- Today: multi-building (several buildings, one company). No per-tenant isolation or branding.

## Reading order

1. This file (`AGENTS.md`)
2. [`docs/architecture.md`](docs/architecture.md) — current and target system map
3. Depending on the task:
   - Security → [`docs/01-security-plan.md`](docs/01-security-plan.md)
   - Refactor / structure → [`docs/02-architecture-plan.md`](docs/02-architecture-plan.md)
   - Buildings / tenants → [`docs/03-multi-tenant-plan.md`](docs/03-multi-tenant-plan.md)
   - Tests / CI → [`docs/04-quality-testing-plan.md`](docs/04-quality-testing-plan.md)
   - Phase priority → [`docs/05-roadmap.md`](docs/05-roadmap.md)
4. Deep diagnosis: [`docs/00-current-state-analysis.md`](docs/00-current-state-analysis.md)

Do not invent an “ideal” architecture that contradicts these plans without explicit user agreement.

## Stack and commands

- SDK: Dart `>=3.4.3 <4.0.0` (see `pubspec.yaml`)
- Package: `administradores_diaz_ph`
- Setup: `flutter pub get` → `flutter run`
- Analysis: `flutter analyze`
- Tests: `flutter test` (almost no real coverage; `test/widget_test.dart` is a broken template)
- Firebase config: `flutterfire configure` → `lib/firebase_options.dart`

No Provider/Riverpod/Bloc. State = `StatefulWidget` + `setState` + SharedPreferences.

## Quick `lib/` map

| Path | What it is |
|---|---|
| `pages/` | Shell tabs (bottom nav) |
| `modals/` | Full-screen CRUD screens (**not** dialogs) |
| `services/` | Auth, generic Firestore, PDF, prefs, platform |
| `models/` | Only `News` and `UserRole` typed; rest is usually `Map` |
| `global_variables.dart` | Hardcoded Diaz PH branding (`Globals`) |

Roles: `UserRole.admin` / `superadmin` / `user` ↔ Firestore `ADMINISTRADOR` / `SUPERADMINISTRADOR` / `CLIENTE`.

## Hard constraints

### Security

- **Do not** commit or regenerate keystores, `key.properties`, or real secrets in the repo.
- **Do not** weaken `.gitignore` to include `key/`, `*.jks`, or credentials.
- **Do not** treat SharedPreferences as the source of truth for authorization when designing new features; the plan is Custom Claims + `firestore.rules`.
- **Do not** assume Firestore rules in the console are safe: they are **not versioned** in this repo. If touching data access, align with [`docs/01-security-plan.md`](docs/01-security-plan.md).
- Client Firebase API keys are not classic “secrets”, but the real barrier must be rules + API key restrictions — do not widen the surface.

### Product / multi-tenant

- **Do not** hardcode more brand data (name, logo, colors, contact) in new widgets. Avoid extending `Globals`; prefer a single source or future per-tenant config.
- When modeling new data, design with **`tenantId` + `buildingId`** in mind (even though code today filters by building name).
- **Do not** treat client-only filtering as completed isolation between buildings/tenants.

### Change scope

- Minimal changes aligned to the task. No mass refactor (`modals/` → `features/`, introduce Riverpod app-wide, etc.) unless the user asks.
- For a local bug or a single screen: touch only what is needed; do not opportunistically rewrite architecture.
- Do not create extra markdown docs unless asked (this AI doc set already exists).

## Code conventions

- End-user UI and messages: **Spanish**.
- Follow existing style: `StatefulWidget`, services instantiated in State, imports via `package:administradores_diaz_ph/...`.
- When adding an entity or CRUD flow:
  - Reuse patterns from `add_*.dart` / `*_page.dart` in `modals/`.
  - Prefer a typed model if introducing new domain.
  - Centralize building filters if touching the query (do not copy-paste the prefs block again if a small extract fits the same change).
- Error handling: do not silently swallow failures with `return []` / `return ''` in new code; propagate or show user feedback consistently with nearby screens.
- Theming: colors are hardcoded today (`Colors.black` / `Colors.white`). Do not invent a parallel design system; if touching theme, move toward central `ThemeData` per the plan.

## Where to put new code

| Change type | Where |
|---|---|
| Shell tab | `lib/pages/` + register in `home_page.dart` |
| Entity CRUD / detail | `lib/modals/` (until the folder is renamed) |
| Reusable Firebase access | `lib/services/` or, better, a dedicated repository if starting the architecture plan |
| Typed model | `lib/models/` |
| Pure utility | `lib/utils/` |

When implementing the architecture plan, prefer `features/<entity>/` and repositories; do not mix both styles in the same PR without need.

## Firestore — known collections

`users`, `buildings`, `news`, `dashboard`, `zonas` (+ `events`), `visits`, `bills`, `complaints`, `votings`.

Dominant filter field today: `edificio` (name string). Target: `buildingId` (+ `tenantId`).

## Roadmap priority (do not skip phases without reason)

0. Security (keystore, versioned rules, claims)  
1. Minimal tests + CI  
2. Typed models, repos, session state, less duplication  
3. Robust multi-building with `buildingId` and `tenantId` in the model  
4. Full multi-tenant (`tenants` collection, dynamic branding, isolation)

Detail: [`docs/05-roadmap.md`](docs/05-roadmap.md).

## Tests

- Before large refactors: real smoke test + model/repo tests per [`docs/04-quality-testing-plan.md`](docs/04-quality-testing-plan.md).
- Expected dev deps when testing starts: `mocktail` / `fake_cloud_firestore`.
- Do not leave the counter template test as fake green: replace it if touching the suite.

## Communicating with the user

- Reply in **Spanish** unless they ask for another language.
- Be direct: what changed, why, and risks (security / multi-tenant) when relevant.
- If a request conflicts with security or the multi-tenant plan, warn and propose the path aligned with `docs/`.

## Quick checklist before finishing a task

- [ ] Does the change respect security and secrets constraints?
- [ ] Does it avoid coupling more branding to Diaz PH?
- [ ] Does it fit the current structure or consciously advance the architecture plan?
- [ ] Is there no out-of-scope refactor?
- [ ] Is `flutter analyze` clean on touched files, if applicable?
