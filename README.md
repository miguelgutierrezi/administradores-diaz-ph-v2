# Administradores Diaz PH

A Flutter application for **Administradores Diaz PH SAS**, a property management (Propiedad Horizontal) company in Colombia. The app lets administrators and residents manage buildings/condominiums, common areas, communications, and administrative documents from a single mobile/web/desktop app.

> **Note:** this repository (`administradores-diaz-ph-v2`) is a **v2 that is not yet deployed to production** — the current production app runs on a separate/earlier project. The goal for this v2 is to use it as the **base for a configurable platform that can serve multiple property management companies**, not just Administradores Diaz PH. See [docs/03-multi-tenant-plan.md](docs/03-multi-tenant-plan.md) for the multi-tenant plan.

## Features

- **News & bulletin board** — announcements and building-wide news feed.
- **Common areas & bookings** — residents can reserve shared zones (e.g. BBQ area, social room) via a calendar.
- **Internal messaging** — chat between residents and administrators.
- **Visits** — visitor registration with PDF report generation.
- **Billing** — management of building invoices/fees.
- **Complaints (PQR)** — residents can file and track complaints.
- **Voting** — building-wide polls and voting.
- **Buildings, clients & admins management** — CRUD screens to manage buildings, residents (clients), and administrators.
- **Push notifications** — Firebase Cloud Messaging topics per building.

## Tech stack

- [Flutter](https://flutter.dev/) (Android, iOS, Web, Windows, Linux, macOS)
- [Firebase](https://firebase.google.com/): Auth, Cloud Firestore, Storage, Cloud Messaging
- `shared_preferences` for local session/state caching
- `pdf` for generating visit reports

## Project structure

```
lib/
├── main.dart                # App entry point
├── global_variables.dart    # Company-wide constants (branding, contact info)
├── login_page.dart / register_page.dart / welcome_page.dart / splash_screen.dart
├── home_page.dart            # Bottom-nav shell (news, dashboard, zones, messages, more)
├── handlers/                 # Platform-specific permission handlers
├── models/                   # Typed data models
├── modals/                   # Full CRUD screens (buildings, clients, admins, visits, bills, complaints, votings, zones...)
├── pages/                    # Main shell pages (dashboard, messages, news, profile, settings, zones)
├── services/                 # Firebase & platform integration layer (auth, firestore, pdf, shared preferences)
└── utils/                    # Shared utilities
```

> Note: `lib/modals/` contains full-screen widgets (not dialogs) for each entity's create/edit/list flow.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.4.3 <4.0.0`)
- A Firebase project with Auth, Firestore, Storage, and Cloud Messaging enabled
- Platform-specific Firebase config files:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `lib/firebase_options.dart` (generated via `flutterfire configure`)

### Setup

```bash
flutter pub get
flutter run
```

To generate/update Firebase configuration:

```bash
flutterfire configure
```

### Building

```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

Android release builds require a signing keystore referenced from `android/app/build.gradle` / `key.properties`. **Do not commit keystores or credentials to version control** — see [docs/01-security-plan.md](docs/01-security-plan.md) for current security remediation items.

## Documentation

### For humans and AI agents

- [AGENTS.md](AGENTS.md) — operating guide for AI agents (constraints, conventions, where to put code)
- [docs/architecture.md](docs/architecture.md) — current system map and target architecture
- [docs/ai/README.md](docs/ai/README.md) — index of agent-oriented docs
- [.cursor/rules/](.cursor/rules/) — scoped Cursor rules (core, Flutter, security, multi-tenant)

### Improvement plans

In-depth analysis and plans under [docs/](docs/):

- [docs/00-current-state-analysis.md](docs/00-current-state-analysis.md) — current architecture & security assessment
- [docs/01-security-plan.md](docs/01-security-plan.md) — security remediation plan
- [docs/02-architecture-plan.md](docs/02-architecture-plan.md) — architecture/refactor plan
- [docs/03-multi-tenant-plan.md](docs/03-multi-tenant-plan.md) — multi-building / multi-tenant configurability plan
- [docs/04-quality-testing-plan.md](docs/04-quality-testing-plan.md) — testing & CI strategy
- [docs/05-roadmap.md](docs/05-roadmap.md) — suggested execution roadmap

## Contributing

This is a private project for Administradores Diaz PH SAS. Please review [AGENTS.md](AGENTS.md), [docs/architecture.md](docs/architecture.md), and the improvement plans in [docs/](docs/) before making architectural changes.
