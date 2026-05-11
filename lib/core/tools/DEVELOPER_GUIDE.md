# Tahseen Developer Guide

Welcome to the **Tahseen** project. This guide explains the architecture, custom automation tools, and workflows used in this project to ensure high productivity and security.

---

## 🏗 Project Architecture

We follow a **Feature-First** architecture combined with **Clean Architecture** principles.

### 1. Folder Structure
- `lib/core`: Shared logic, utilities, constants, and global configurations.
- `lib/features/screens`: Contains independent modules (features). Each feature is structured as:
    - `controller/`: Cubits and State classes.
    - `data/repo/`: Repositories (Remote/Local).
    - `data/model/`: Data models (using Freezed).
    - `service/`: Business logic layer that coordinates between repos and cubits.
    - `ui/`: Flutter widgets and screens.

### 2. Tech Stack
- **State Management:** `flutter_bloc` (Cubit).
- **Navigation:** `auto_route` (Declarative routing).
- **Networking:** `dio` with custom error handling.
- **Functional Programming:** `dartz` for `Either<Failure, Success>`.
- **Dependency Injection:** `get_it` (Service Locator).

---

## 🛠 Automation Tools

All scripts are located in `lib/core/tools`. They are designed to eliminate boilerplate and human error.

### 1. Flavor & Environment Management
**Tools:** `flavors/`
- **`add_new_flavor.dart`**: Adds a complete new environment.
  - Updates Dart Enums, Pubspec YAML, Android Gradle, and creates flavor folders automatically.
  - Usage: `dart run lib/core/tools/flavors/add_new_flavor.dart <name>`
- **`switch_default_flavor.dart`**: Sets the "Global Default" for the project.
  - Swaps **Package IDs**, **Dart Config**, and **Firebase Config** (google-services.json) to the chosen flavor.
  - Usage: `dart run lib/core/tools/flavors/switch_default_flavor.dart <name>`
- **`setup_flavorizr.dart`**: Initial project-wide configuration for the flavorizr engine.

### 2. Feature Scaffolding
**Tool:** `create_auto_files/main_script.dart`
- **Purpose:** Generates the complete folder structure and boilerplate files for a new feature.
- **Usage:** `dart run lib/core/tools/create_auto_files/main_script.dart <FeatureName>`
- Automatically registers the feature in the Service Locator (`sl`) and updates the Router.

### 3. API Function Injection
**Tool:** `create_auto_functions/add_function_script.dart`
- **Purpose:** Injects a new API endpoint across all layers (Repo -> Service -> State -> Cubit).
- **Usage:** `dart run lib/core/tools/create_auto_functions/add_function_script.dart <FeatureName> <FunctionName> <ReturnType> <ParamType>`
- Handles **Cache Keys**, **KeyCode generation**, and **Automatic Request Cancellation**.

### 4. Model & Entity Creation
**Tool:** `model_creation/create_entity.dart`
- **Purpose:** Converts a raw JSON response into a production-ready Freezed Entity.
- **Usage:** Paste JSON into `data.json` and run the script.

### 5. Utility Tools
- **`asset_image_extractor.dart`**: Generates constants for image assets.
- **`files_Exporter/files_expoerter_run.dart`**: Bundles specific files into a single output for AI analysis or documentation.

---

## 🔄 Standard Workflows

### workflow 1: Adding a New Flavor
1. Run `add_new_flavor.dart <name>`.
2. Place `google-services.json` in `android/app/src/<name>/`.
3. Place `GoogleService-Info.plist` in `ios/Runner/Firebase/<name>/`.
4. Run the generated flavorizr command provided by the script.

### workflow 2: Switching Development Context
If you want to work on a specific flavor without typing `--flavor` every time:
1. Run `switch_default_flavor.dart <name>`.
2. Your project root will now use that flavor's IDs and Firebase config as the default.

---

## 🔐 Security Standards

The project is designed with a high security bar:
1. **SSL Pinning:** Handled via `http_certificate_pinning`.
2. **Device Attestation:** Uses `app_attest_integrity` to ensure the app is running on a real, untampered device.
3. **Request Cancellation:** Every API call is tracked by a `KeyCode`. When a Cubit is disposed, all pending requests for that Cubit are automatically cancelled via `CancelManager`.
4. **Firebase Isolation**: Each flavor has its own Firebase project/config, strictly separated at the native level.

---

## 📝 Coding Standards

- **Extensions:** Use `BuildContext` extensions for navigation (e.g., `context.push(...)`).
- **Lints:** We use `custom_lint` for project-specific rules. Ensure your IDE shows no warnings before committing.
- **Models:** Always use `Freezed` for data models to ensure immutability.
- **DI:** Always register new services/repos in `lib/core/di/injection.dart` (the scaffolding tools handle this for you).
