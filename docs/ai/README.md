# Documentation for AI agents

This folder complements the improvement plans (`00`–`05`) with material so agents (Cursor, Claude Code, Copilot, etc.) stay aligned with the product.

## Main entry points

| File | Use |
|---|---|
| [`../../AGENTS.md`](../../AGENTS.md) | **Read first.** Constraints, conventions, where to put code, checklist. |
| [`../architecture.md`](../architecture.md) | Current system map, Firestore collections, roles, target architecture. |
| [`../../.cursor/rules/`](../../.cursor/rules/) | Persistent Cursor rules (always / by glob). |
| [`../../CLAUDE.md`](../../CLAUDE.md) | Claude Code entry point (imports `AGENTS.md`, adds tool-specific notes). |
| [`../../.github/copilot-instructions.md`](../../.github/copilot-instructions.md) | GitHub Copilot entry point. |

## Cursor rules

| Rule | When it applies |
|---|---|
| `project-core.mdc` | Always |
| `flutter-dart.mdc` | Files under `lib/**/*.dart` |
| `security-firebase.mdc` | Services, Firebase rules, android/ios/key |
| `data-multitenant.mdc` | Models, FirestoreService, Globals |

## Relationship to plans

Agents **do not replace** the plans: they summarize and point to them.

1. Blocking security → `01-security-plan.md`
2. Refactor → `02-architecture-plan.md`
3. Multi-building / multi-tenant → `03-multi-tenant-plan.md`
4. Tests → `04-quality-testing-plan.md`
5. Phase order → `05-roadmap.md`

Full diagnosis: `00-current-state-analysis.md`. System map: `architecture.md`.
