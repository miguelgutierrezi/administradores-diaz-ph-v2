# Quality and testing plan

## 1. Current state

The only test file, [`test/widget_test.dart`](../test/widget_test.dart), is the default `flutter create` template (looks for the demo counter `0`/`1`). It does not match this app and **would fail if run**. There is no real coverage of any kind (unit, widget, integration, Firestore rules).

## 2. Priorities

Before the architecture refactor ([`02-architecture-plan.md`](02-architecture-plan.md)) or multi-tenant work ([`03-multi-tenant-plan.md`](03-multi-tenant-plan.md)), establish a minimal safety net:

- [ ] Replace `test/widget_test.dart` with a real smoke test (app starts and shows `welcome_page` or `login_page` without exceptions).
- [ ] Add `mocktail` (or `mockito`) as a `dev_dependency`.

## 3. Unit tests (highest priority, highest ROI)

- [ ] Tests for new typed models (`fromJson`/`toJson`/`copyWith`) from the [architecture plan](02-architecture-plan.md).
- [ ] Repository tests using `fake_cloud_firestore` (in-memory Firestore) — test building-filter queries without real credentials.
- [ ] Tests for `AuthService` and `SharedPreferencesService` mocking `FirebaseAuth`/`SharedPreferences`.
- [ ] Tests for pure utilities (`Utils`, email validators, date formatting).

## 4. Widget tests

- [ ] Cover critical forms: login, register, `add_client`, `add_building` — verify validations (required fields, email format) without real Firebase (inject fake repositories).

## 5. Security rules tests (once `firestore.rules` exist)

- [ ] Use `@firebase/rules-unit-testing` (Node, runs in CI with the Firestore emulator) to verify:
  - A client of building A cannot read/write building B data.
  - A user without `ADMINISTRADOR`/`SUPERADMINISTRADOR` cannot write to `buildings`.
  - (If Phase B multi-tenant is implemented) a user of tenant X cannot access tenant Y data under any condition.

## 6. Continuous integration (CI)

- [ ] Configure GitHub Actions so each PR runs:
  - `flutter analyze` (use existing [`analysis_options.yaml`](../analysis_options.yaml); tighten lints if needed).
  - `flutter test` (unit + widget tests).
  - `firebase emulators:exec` with rules tests, once they exist.
- [ ] Block merge to `main` if the pipeline fails.

## 7. Suggested progress metric

Do not chase an arbitrary coverage % from day one; prioritize coverage of:
1. Multi-building/tenant security rules (most critical given client-only authorization today).
2. Data repositories (building-filter logic, currently duplicated and unverified).
3. Models (`fromJson`/`toJson` — easy, high value for catching regressions when typing the domain).
