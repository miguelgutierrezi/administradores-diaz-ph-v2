# Security plan (highest priority)

These findings should be fixed **before or in parallel with** any architecture or multi-tenancy work, because they represent active risk today.

## 1. Rotate and remove the signing keystore from the repository

**Problem:** [`key/keystore.jks`](../key/keystore.jks) is committed. Anyone with read access can sign and distribute forged builds impersonating the original Play Store publisher.

**Actions:**
- [ ] Remove `key/` from the repository (`git rm --cached`, not only future `.gitignore`).
- [ ] Purge git history (`git filter-repo` or BFG Repo-Cleaner) to remove the keystore blob from all past commits.
- [ ] Generate a **new** keystore if there is any suspicion of public exposure (a private repo lowers urgency but does not eliminate it if external collaborators existed or the repo was ever public).
- [ ] Move the keystore to a secrets manager (GitHub Actions secrets, Google Cloud Secret Manager, 1Password, etc.) and document the build/signing process under `docs/`.
- [ ] Add to `.gitignore`: `key/`, `*.jks`, `*.keystore`, `key.properties`.

## 2. Keep Firebase credentials out of version control (best practice)

**Problem:** [`android/app/google-services.json`](../android/app/google-services.json), [`ios/Runner/GoogleService-Info.plist`](../ios/Runner/GoogleService-Info.plist), and [`lib/firebase_options.dart`](../lib/firebase_options.dart) contain API keys in plaintext.

**Context:** Firebase client API keys are not secret by design (they are gated by security rules and API key restrictions in Google Cloud Console), but **good practice** recommends:
- [ ] Restrict each API key in Google Cloud Console to the app’s services and `SHA-1`/bundle IDs.
- [ ] Add these files to `.gitignore` and provide them via CI/CD (secrets) or templates (`google-services.json.example`) for new developers.
- [ ] Confirm that Firestore/Storage security rules (see item 3) are the real authorization barrier, not the key secrecy.

## 3. Version and harden `firestore.rules` / `storage.rules`

**Problem:** no security rules are versioned in the repo. There is no way to audit or PR-review how data access is protected.

**Actions:**
- [ ] Create `firestore.rules` and `storage.rules` at the project root, plus `firebase.json` to deploy via `firebase deploy --only firestore:rules,storage`.
- [ ] Minimum recommended rules:
  - All access requires `request.auth != null`.
  - Building read/write limited to users whose `users/{uid}` document includes that building (`resource.data.edificio` / claim), validated **server-side**, not trusting the client.
  - Writes to administrative collections (`buildings`, admins) restricted to `rol == 'ADMINISTRADOR'` or `'SUPERADMINISTRADOR'`, verified by reading `users/{request.auth.uid}` inside the rule.
  - Disable “test mode” rules (`allow read, write: if true`) if they exist in the console today.
- [ ] Add rules tests with `@firebase/rules-unit-testing` (Node) to the CI pipeline.

## 4. Move role authorization from client to server

**Problem:** [`lib/services/auth_service.dart`](../lib/services/auth_service.dart) gets the role from SharedPreferences. If Firestore rules do not independently validate `rol`, app authorization is cosmetic.

**Actions:**
- [ ] Migrate role to **Firebase Auth Custom Claims** (set from a Cloud Function with admin privileges) so the role travels signed in the ID token and can be checked in `firestore.rules` via `request.auth.token.rol`.
- [ ] Keep SharedPreferences only as a UI cache, never as the source of truth for authorization.
- [ ] Revalidate role in every sensitive Cloud Function (do not trust a role sent from the client on HTTP/callable calls).

## 5. Encrypt or minimize sensitive local storage

**Actions:**
- [ ] Evaluate moving `userId` and sensitive session data from SharedPreferences to `flutter_secure_storage` (native Keychain/Keystore).
- [ ] Review which fields truly need local persistence; reduce exposure on compromised/rooted devices.

## 6. Tracking checklist

| Finding | Severity | Status |
|---|---|---|
| Keystore committed | Critical | Pending |
| Firestore/Storage rules not versioned | High | Pending |
| Role validated only on client | High | Pending |
| Firebase credentials in repo without `.gitignore` | Medium | Pending |
| Unencrypted SharedPreferences for session data | Medium | Pending |
