# Architecture and code-quality plan

Goal: reduce massive duplication, type the domain, and prepare so that the “active building/tenant” is configurable in one place (prerequisite for the [multi-tenant plan](03-multi-tenant-plan.md)). See also the living system map in [`architecture.md`](architecture.md).

## 1. Rename and reorganize folders

- [ ] Rename `lib/modals/` → `lib/screens/` (or `lib/features/<entity>/`). Today the name confuses: these are full screens, not dialogs.
- [ ] Consider feature-based organization instead of by type, for example:
  ```
  lib/features/buildings/{model, repository, screens}
  lib/features/clients/{model, repository, screens}
  lib/features/visits/{model, repository, screens}
  ```
  This groups what changes together and makes it easier to see what is “core” vs “per-tenant”.

## 2. Introduce typed models for all entities

Today only `News` and `UserRole` are classes. Create models for: `Building`, `Client`, `Admin`, `Visit`, `Bill`, `Complaint`, `Voting`, `Zone`, `Announce`, with:
- [ ] Constructor + `fromJson`/`fromFirestore` + `toJson`.
- [ ] `copyWith` for immutable updates.
- [ ] Required-field validation in the constructor or a `validate()` method.

Direct benefit: removes typo bugs on `Map<String, dynamic>` keys and enables safer refactors via the static analyzer.

## 3. Per-entity repository layer

Replace direct use of the generic `FirestoreService` in each screen with specific repositories:

```dart
class BuildingRepository {
  Future<List<Building>> getBuildingsForUser(String userId);
  Future<Building> getById(String id);
  Future<void> create(Building building);
  Future<void> update(Building building);
}
```

- [ ] Each repository encapsulates the `where('edificio', ...)` queries duplicated across 10+ files today.
- [ ] Repositories enable mocking in tests (impossible today without abstractions).
- [ ] Consistent error handling: define custom exceptions (`AppException`, `NotFoundException`, `PermissionDeniedException`) and catch them once in the UI layer.

## 4. Adopt a state manager

Currently `StatefulWidget` + `setState()` everywhere, and “active building”/role are re-read from SharedPreferences on every screen.

- [ ] Adopt **Riverpod** (recommended: testable, no `BuildContext` in logic, good code-gen support) or Provider for a simpler migration.
- [ ] Create a single `SessionController`/`AppUserProvider` exposing: current user, role, assigned buildings, active building/tenant. All UI consumes this provider instead of reading SharedPreferences directly.
- [ ] This is the real technical prerequisite for “select active building from a UI selector” (see multi-tenant plan).

## 5. Remove duplication in add/edit screens

The `add_X.dart` / `edit_X.dart` pairs (building, client, admin, news, visit, voting, zone, complaint, bill, announce) repeat:
- Loading dialogs (`_showLoader`)
- Alert/error dialogs
- Email validators
- Loading the current user’s building list

**Actions:**
- [ ] Extract shared widgets: `LoadingDialog`, `AlertDialogHelper`, `EmailValidator` (pure function), `BuildingSelectorField`.
- [ ] Extract a shared `FormScreenBase`/mixin for the “form + save + loader + alert” pattern that is copy-pasted today.

## 6. Centralized theming

- [ ] Define full `ThemeData` in `main.dart` (primary/secondary colors, `AppBarTheme`, typography) instead of hardcoded `Colors.black`/`Colors.white` per screen.
- [ ] This is also a prerequisite for per-tenant branding (configurable brand colors).

## 7. Update dependencies

- [ ] Update Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`) to current versions, reviewing breaking changes.
- [ ] Add `mocktail` or `mockito` as a dev dependency to enable repository/service tests.

## 8. Suggested execution order

1. Typed models (low risk, high value, does not break UI).
2. Per-entity repositories (use the new models).
3. Extract shared widgets in add/edit screens.
4. Adopt state manager and `SessionController`.
5. Centralized theming.
6. Update dependencies (last, once tests can catch regressions).

See [`04-quality-testing-plan.md`](04-quality-testing-plan.md) for covering these changes with tests before/during the refactor.
