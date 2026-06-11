# Deployment & CI/CD Pipeline

Xenova Health utilizes a robust deployment pipeline managed entirely through **GitHub Actions**. This ensures that every code change is validated, tested, and safely deployed to the appropriate environment.

---

## Environment Variables & Build Flavors

The project is structured with three distinct Android product flavors, mapped to three environment configurations.

| Flavor | Package Name / App ID | Environment File | Target Audience |
|---|---|---|---|
| **Dev** | `com.xenovahealth.xenova_health.dev` | `assets/env/dev.env` | Local Developers |
| **Staging** | `com.xenovahealth.xenova_health.staging` | `assets/env/staging.env` | QA & Beta Testers |
| **Prod** | `com.xenovahealth.xenova_health` | `assets/env/prod.env` | Google Play Store |

> [!WARNING]
> Environment files (`.env`) contain sensitive API keys (Gemini, USDA) and are strictly excluded from version control via `.gitignore`. 

---

## GitHub Actions Workflows

We rely on four automated workflows located in `.github/workflows/`:

### 1. PR Validation (`pr_validation.yml`)
**Trigger:** Pull Requests against the `main` branch.
**Actions:**
- Runs `flutter pub outdated` to flag dependency drift.
- Runs `flutter analyze` to enforce strict Dart linting rules.
- Runs `flutter test` to ensure no regressions in business logic.
- Blocks the PR from merging if any step fails.

### 2. Staging Builds (`build_android.yml`)
**Trigger:** Merges/Pushes to the `main` branch.
**Actions:**
- Injects Staging API keys securely from **GitHub Secrets** into a temporary `staging.env` file.
- Validates the existence of Firebase configuration files.
- Executes `flutter build apk --flavor staging --release` and `flutter build appbundle --flavor staging --release`.
- Uploads the artifacts (.apk and .aab) to the GitHub Action run for QA engineers to download and test.

### 3. Release Checklist (`release_checklist.yml`)
**Trigger:** Manual Dispatch (`workflow_dispatch`).
**Actions:**
- A final safety net before a production cut.
- Re-runs all linting and testing.
- Verifies that `firebase_options.dart` and `prod.env.example` templates exist.

### 4. Production Release (`release_build.yml`)
**Trigger:** Pushing a Git Tag (e.g., `v1.0.0`).
**Actions:**
- Injects Production API keys from GitHub Secrets.
- Reconstructs the secure `upload-keystore.jks` using a Base64 encoded secret.
- Injects the `key.properties` variables (Store Password, Key Alias, Key Password).
- Executes `flutter build appbundle --flavor prod --release`.
- Outputs a fully signed Android App Bundle (`app-prod-release.aab`) ready to be uploaded to the Google Play Console.

---

## Firebase Configuration Setup (Manual Prep)

Before the CI/CD pipeline can run successfully, the repository must be linked to Firebase:

1. Create 3 Firebase Projects (or 1 project with 3 registered Apps).
2. Run FlutterFire CLI locally to generate the Dart configurations:
   ```bash
   flutterfire configure --project=xenova-prod-project --out=lib/firebase_options.dart
   flutterfire configure --project=xenova-staging-project --out=lib/firebase_options_staging.dart
   flutterfire configure --project=xenova-dev-project --out=lib/firebase_options_dev.dart
   ```
3. Ensure these generated files are committed to the repository (they do not contain sensitive secrets, only public identifiers).

---

## Versioning Strategy

Xenova Health strictly adheres to **Semantic Versioning (SemVer)**:
- `MAJOR.MINOR.PATCH` (e.g., `1.2.4`)
- Versions are tracked directly in `pubspec.yaml`.
- Bumping the version requires updating `pubspec.yaml` (e.g., `version: 1.2.4+14`), committing the change, and running `git tag v1.2.4 && git push --tags` to trigger the Production Release pipeline.
