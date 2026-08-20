# Current state analysis

## 1. App purpose

Flutter application (Android/iOS/Web/Desktop) for **Administradores Diaz PH SAS**, a Colombian Propiedad Horizontal management company. It is not a generic product: it is the app *of one specific management company* for the buildings/complexes it administers.

Main features (see [`lib/home_page.dart`](../lib/home_page.dart)): News, bulletin board/Dashboard, common areas with bookings, internal messaging, and an admin module for: buildings, clients (residents), administrators, visits (with PDF generation), bills, complaints, votings, calendar, and announcements.

Roles ([`lib/models/user_role.dart`](../lib/models/user_role.dart)): `admin`, `superadmin`, `user` (`ADMINISTRADOR`, `SUPERADMINISTRADOR`, `CLIENTE` in Firestore).

## 2. Current architecture

No formal architecture (no MVC/MVVM/Clean Architecture). Organization is “by file type”:

- **`lib/modals/`**: misleading name — ~25 full CRUD screens (`StatefulWidget` + `Scaffold`), not modal dialogs.
- **`lib/pages/`**: 6 main shell pages (bottom nav).
- **`lib/services/`**: Firebase, SharedPreferences, PDF, and platform detection.
- **`lib/models/`**: only `News` and `UserRole` are typed; other entities (building, client, visit, bill, complaint, voting, zone) travel as `Map<String, dynamic>` with no schema validation.
- **`lib/handlers/`**: a single file for Android alarm permissions.

No UI/business-logic separation: widgets call Firestore directly and own form validation.

## 3. State management

**No state manager** (no Provider/Riverpod/Bloc/GetX). Everything uses `StatefulWidget` + `setState()`. Active building and user role are stored in plaintext SharedPreferences and re-read on every screen, producing the duplicated pattern:

```
edificio(s) = sharedPreferencesService.getDynamicList('edificio')
query.where('edificio', isEqualTo/whereIn: ...)
```

repeated in at least 10 files (`dashboard_page.dart`, `news_page.dart`, `zones_page.dart`, `clients_page.dart`, `complaints_page.dart`, `votings_page.dart`, `visits_page.dart`, `calendar_page.dart`, `bills_page.dart`).

## 4. Services (`lib/services/`)

- **`auth_service.dart`**: `FirebaseAuth` wrapper. `getCurrentUserRole()` reads the role **from local SharedPreferences**, not from custom claims, and does not revalidate against Firestore — authorization risk.
- **`firestore_service.dart`**: generic Firestore/Storage CRUD, no per-entity repositories. Detected collections: `users`, `buildings`, `zonas` (subcollection `events`), `visits`, and via indirect use `news`, `bills`, `complaints`, `votings`, `announces`/`dashboard`.
- **`pdf_service.dart`**: visit PDFs with company data **hardcoded from `Globals`**.
- **`platform_service.dart`**: trivial platform detection helpers.
- **`shared_preferences_service.dart`**: mixes SharedPreferences CRUD with FCM logic (`clearPrefs` unsubscribes topics), violating cohesion.

No interfaces/abstractions, no dependency injection, inconsistent error handling (mix of `rethrow`, `catch` + `debugPrint`, and silent empty returns).

## 5. Data models

Only `News` and `UserRole` are typed classes. Other entities travel as `Map<String, dynamic>` throughout the UI, without `fromJson`/`toJson`/`copyWith`, with typo risk on map keys.

## 6. Relevant dependencies (`pubspec.yaml`)

Firebase: `firebase_core ^2.0.0`, `firebase_auth ^4.0.0`, `cloud_firestore ^4.0.0`, `firebase_storage ^11.0.0`, `firebase_messaging ^14.9.4` (outdated vs current 3.x/5.x lines). No state-management packages. No `mockito`/`mocktail`. Only default `flutter_test`.

## 7. `lib/global_variables.dart` — the key coupling point

```dart
class Globals {
  static String mainAddress = "Cra. 18 #78-40, Oficina 305";
  static String phoneNumber = "601 - 7369032";
  static String mainName = "Administradores Diaz PH SAS";
  static String mainSlogan = "Administración de Propiedad Horizontal";
  static String mainEmail = "diazmartinezadmon@gmail.com";
}
```

Hardcoded company identity (used in `welcome_page.dart` and `pdf_service.dart`). Not from remote config, Firestore, or env/flavors. **Shipping for another management company would require editing source and rebuilding.** The logo (`assets/Logo_Diaz_Administradores.jpeg`) is also hardcoded.

## 8. Building model — multi-building, not multi-tenant

- The `buildings` collection already models **N buildings** (name, address, description, zones, image).
- A `CLIENTE` belongs to **one** building (simple string in SharedPreferences/Firestore).
- An `ADMINISTRADOR` manages a **list** of buildings (array).
- A `SUPERADMINISTRADOR` sees everything without a filter.
- Filtering uses **building name (`String`)**, not document ID — brittle on rename, no referential integrity.
- FCM topics are derived from the normalized building name (`news_${building.toLowerCase()...}`), coupled to that string.

**Conclusion:** multi-building within a single company exists, but there is **no tenant/management-company concept** (no `tenantId`/`companyId` on documents, no per-company branding or config).

## 9. Security — critical findings

- **No versioned `firestore.rules`, `storage.rules`, or `firebase.json`** in the repo. Security rules have no change control or PR review.
- **Client-only authorization**: role is read from SharedPreferences, not revalidated server-side on each sensitive operation.
- **Committed secrets/credentials**:
  - [`android/app/google-services.json`](../android/app/google-services.json) — Firebase Android API key in plaintext.
  - [`ios/Runner/GoogleService-Info.plist`](../ios/Runner/GoogleService-Info.plist) — Firebase iOS API key.
  - [`lib/firebase_options.dart`](../lib/firebase_options.dart) — API keys embedded in Dart.
  - **`key/keystore.jks`** committed — **critical**: anyone with repo access can sign forged app builds.
  - Root `.gitignore` does not exclude `key/`, `*.jks`, `google-services.json`, or `GoogleService-Info.plist`.
- All local state (including `userId`, role, building) is stored unencrypted in SharedPreferences (no `flutter_secure_storage`).

## 10. Quality, tests, and other code smells

- **Tests**: only [`test/widget_test.dart`](../test/widget_test.dart), the default `flutter create` counter template, which **would fail if run**. No real tests.
- **Massive duplication**: `add_X.dart`/`edit_X.dart` pairs nearly line-for-line repeat loaders, alerts, email validators, and loading the user’s buildings.
- **Error handling** inconsistent across services.
- **No centralized theming**: hardcoded `Colors.black`/`Colors.white` on each AppBar instead of `ThemeData`.
- Misleading folder name `lib/modals/`.

## 11. How far from configurable / multi-tenant

At minimum this would require:

1. Remove static `Globals` → dynamic per-tenant config (Firestore or Remote Config): brand, logo, contact, theme.
2. Introduce `tenantId`/`companyId` in the data model as the partition key and in security rules.
3. Version `firestore.rules`/`storage.rules` and enforce server-side authorization.
4. Remove keystore and credentials from version control (urgent, independent of roadmap).
5. Domain/repository layer with typed models + state manager (Provider/Riverpod/Bloc).
6. Real test coverage before any large refactor.

See following documents for detail and action plans. Also: [`architecture.md`](architecture.md).
