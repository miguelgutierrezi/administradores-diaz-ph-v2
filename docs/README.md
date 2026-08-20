# Improvement documentation — Administradores Diaz PH

This directory holds the current-state analysis and proposed improvement plans.

## Project context

> **Important:** this repository (`administradores-diaz-ph-v2`) is a **v2 not yet in production** — production runs on a different/earlier project. The stated goal of this v2 is to use it as the **base for a configurable platform that can serve multiple Propiedad Horizontal management companies**, not only Administradores Diaz PH. That means the **multi-tenant** plan (see [03-multi-tenant-plan.md](03-multi-tenant-plan.md)) is the **central roadmap goal**, not a nice-to-have.

## Documentation for AI agents (repo root + here)

- [../AGENTS.md](../AGENTS.md) — Operating instructions for agents (constraints, conventions, checklist).
- [architecture.md](architecture.md) — Current and target architecture map.
- [ai/README.md](ai/README.md) — Index of agent-oriented docs.
- [../.cursor/rules/](../.cursor/rules/) — Cursor rules by area (core, Flutter, security, data/multi-tenant).

## Plan index

1. [00-current-state-analysis.md](00-current-state-analysis.md) — Technical diagnosis of current code, architecture, and security.
2. [01-security-plan.md](01-security-plan.md) — Critical security findings and remediation (highest priority).
3. [02-architecture-plan.md](02-architecture-plan.md) — Architecture refactor, typed models, state management, deduplication.
4. [03-multi-tenant-plan.md](03-multi-tenant-plan.md) — Evolving the app for per-building/complex configurability and multi-company (multi-tenant).
5. [04-quality-testing-plan.md](04-quality-testing-plan.md) — Testing, CI, and quality strategy.
6. [05-roadmap.md](05-roadmap.md) — Suggested prioritization and execution phases.

## Executive summary

The **Administradores Diaz PH** app is a working Flutter application for Propiedad Horizontal management for one specific company. It already supports **multiple buildings/complexes within the same company** (multi-building), but is **tightly coupled to that company’s brand** (hardcoded name, logo, contact) and has **critical security risks** (committed credentials and signing keystore, no versioned `firestore.rules`, authorization roles validated only on the client).

Because the goal is to turn this v2 into a multi-tenant product base, fix security findings first (see [01-security-plan.md](01-security-plan.md)) before building on the current data model — they are blocking regardless of product roadmap and much cheaper to fix now while there is no real multi-customer production data on this codebase.
