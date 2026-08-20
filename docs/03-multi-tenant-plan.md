# Multi-building / multi-tenant configurability plan

> **Project context:** this repository (`administradores-diaz-ph-v2`) is a v2 that is **not published to production** (current production runs on a different/earlier project). The stated goal is to use this v2 **as the base for a configurable platform serving multiple Propiedad Horizontal management companies**, not only Administradores Diaz PH. Therefore **Phase B (multi-tenant) is not optional: it is the project goal**. Starting from a v2 without real production data means the data model can be designed multi-tenant **from the start**, instead of migrating live customer data later.

## Context: two levels of “configurable”

Keep these problems separate:

1. **Multi-building (partially exists):** one management company administers several buildings/complexes. This is **already modeled** in Firestore (`buildings` collection, `edificio` field on users), though fragile (by name string, duplicated code).
2. **Multi-tenant (does not exist):** the app serves **different management companies**, each with its own brand (logo, name, colors, contact), buildings, users, and isolated data. This **does not exist** — everything (`Globals`, logo, PDFs) is hardcoded to one company.

Recommendation: **first mature level 1 (robust multi-building)**, because Phase B builds directly on that model (a tenant still has N buildings). Given the project goal is Phase B, design Phase A **already thinking about `tenantId`** (even if only one real tenant exists initially) to avoid a second data migration.

## Phase A — Robust multi-building (same tenant, several buildings)

Improvements so multi-building management is solid and not dependent on fragile strings:

- [ ] Reference buildings by **`buildingId`** (Firestore document ID) instead of name string in all collections (`users`, `visits`, `news`, `bills`, `complaints`, `votings`, `announces`/`dashboard`, `zonas`).
- [ ] Migrate existing data (one-shot script) from `edificio: "Name"` to `edificioId: "<docId>"`, keeping the name only as a denormalized display field if useful for performance.
- [ ] Centralize “active building” in the `SessionController` proposed in the [architecture plan](02-architecture-plan.md), with a building selector in the UI for admins who manage several.
- [ ] Change FCM topics from normalized name to `edificioId` (stable if the building is renamed).
- [ ] Firestore rules that validate membership via `edificioId` using the user’s token/custom claim (see [security plan](01-security-plan.md) item 4), not only client-side queries.
- [ ] Allow *per-building* operational config that is global or missing today: own common areas, booking rules, admin fees, invoice fields.

This level already solves much of “make it configurable for different buildings” without full multi-tenancy.

## Phase B — Multi-tenant (several management companies)

To offer the app as a product to other PH management companies:

### B.1 Data model

- [ ] New root collection `tenants/{tenantId}` with: company name, slogan, logo (Storage URL), brand colors, contact (address, phone, email), domain/subdomain if applicable.
- [ ] Add `tenantId` to **all** existing collections (`buildings`, `users`, `visits`, `news`, `bills`, etc.) as the partition field.
- [ ] `buildings` belong to a `tenantId`; one company’s buildings are never visible to another.

### B.2 Security and isolation

- [ ] Firestore rules requiring `resource.data.tenantId == request.auth.token.tenantId` on every read/write (custom claim `tenantId` set with the role).
- [ ] Storage with paths partitioned by tenant (`tenants/{tenantId}/buildings/{buildingId}/...`) and equivalent rules.
- [ ] Review that no Cloud Function or query can cross tenants by mistake (rules tests for this case; see [04-quality-testing-plan.md](04-quality-testing-plan.md)).

### B.3 Dynamic branding (replace `Globals`)

- [ ] Remove static `lib/global_variables.dart`.
- [ ] Load active tenant config at login (or resolve by domain/flavor for dedicated apps) from `tenants/{tenantId}` and expose it via `SessionController`/provider.
- [ ] Use that config in: `welcome_page.dart`, `login_page.dart`, `pdf_service.dart` (PDF headers), `ThemeData` (brand colors), icon/splash if dedicated per-tenant builds are generated.
- [ ] Define distribution strategy: one app that detects tenant at login (SaaS multi-tenant)? Or separate builds per tenant via [Flutter flavors](https://docs.flutter.dev/deployment/flavors) reusing the same code? Depends on business model (dedicated store listing with own icon vs white-label shared app with company login).

### B.4 Tenant management and onboarding

- [ ] Panel/flow (can be internal, not in the public app) to create a new tenant: brand data, first superadmin, initial building.
- [ ] Define plan/limit model if commercializing (building count, users, storage) — outside pure tech scope, but affects the data model (`tenants/{tenantId}.plan`, limits).

## Recommended decision

Given this v2’s explicit goal is to become the base of a multi-tenant platform for PH management companies, and that **there is no real production data on this codebase yet** (production runs elsewhere):

1. Execute the [security plan](01-security-plan.md) (blocking, independent of the rest) — cheaper to fix now, with no production customer data to migrate.
2. Design the Phase A data model **including `tenantId` from the start** (even if only the “Administradores Diaz PH” tenant exists initially), avoiding a later migration of live production data.
3. Complete Phase A (robust multi-building) on that `tenantId` model.
4. Advance directly to Phase B (full isolation, dynamic branding, tenant onboarding) as the natural continuation — the roadmap goal, not a “nice to have”.

This sequence avoids the biggest risk of deferring Phase B “until there is a business case”: if by then real customers are already on a model without `tenantId`, migration is far more expensive and risky than designing correctly now while the project remains v2/pre-production.
