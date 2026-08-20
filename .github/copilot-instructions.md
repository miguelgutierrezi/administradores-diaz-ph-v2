# Copilot instructions for Administradores Diaz PH v2

Use these notes as the default context for this repository.

## Project context

- Flutter + Firebase app for property management.
- This repo is **pre-production**; the product goal is a **multi-tenant** platform.
- Today the app is mostly multi-building, not fully tenant-isolated.

## Read first

Before making structural or data-model changes, read:

1. `AGENTS.md`
2. `docs/architecture.md`
3. The relevant plan:
   - `docs/01-security-plan.md`
   - `docs/02-architecture-plan.md`
   - `docs/03-multi-tenant-plan.md`
   - `docs/04-quality-testing-plan.md`
   - `docs/05-roadmap.md`

## Core constraints

- Do not commit secrets, keystores, or credentials.
- Do not hardcode more branding data in widgets or extend `Globals` casually.
- Do not treat `SharedPreferences` as real authorization.
- Keep changes minimal and aligned to the current structure unless the user asks for a broader refactor.
- Do not invent an architecture that contradicts the plans above.

## Codebase conventions

- User-facing text should be in **Spanish**.
- Existing style is `StatefulWidget` + `setState` + services instantiated in state.
- `lib/modals/` contains full-screen CRUD screens, not dialogs.
- Prefer reusing existing patterns before introducing new abstractions.
- When touching Firestore data, think in terms of `tenantId` + `buildingId`, even if the current code still filters by `edificio`.

## Practical reminders

- Follow the existing Firestore/security plan when changing data access.
- Avoid broad refactors, app-wide state management rewrites, or new design systems unless explicitly requested.
- When in doubt, preserve current behavior and only change what the task needs.
