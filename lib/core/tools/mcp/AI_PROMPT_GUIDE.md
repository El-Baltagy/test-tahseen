# 🤖 AI Technical Command: Professional UI & Architecture Rules

> [!NOTE]
> Figma credentials are stored globally in `~/.figma_mcp_credentials.json` to be shared across projects.

> [!IMPORTANT]
> This protocol is MANDATORY for building any UI in this project. You must strictly follow the architectural patterns established in the project's automation scripts.

## 1. 🏗️ Professional UI Architecture (AutoRouter & BLoC)
When building a screen, you must follow the `AutoRouteWrapper` pattern as seen in generated features:
- **Annotations**: Use `@RoutePage()` for the screen class.
- **Dependency Injection**: Implement `AutoRouteWrapper` and use `wrappedRoute` to provide the screen's Cubit using `AppSingleton()`.
- **State Management**: Use `BlocListener` and `BlocBuilder` correctly within the build method.
- **Lifecycle**: Use an abstract `BaseState` class extending `State<T>` to handle `initState`, `dispose`, and shared variables like `Cubit.get()`.

## 2. 🧩 Widget Extraction & Asset Management
- **Rule**: NEVER build the entire UI within the main screen file.
- **Extraction**: Every distinct UI component (Button, Card, Header, etc.) must be extracted into a separate file inside a `widgets` folder within the feature's `ui` directory.
- **Assets (Images & SVGs)**: 
  1. Identify image or vector nodes in Figma.
  2. Use Figma API to export them (PNG for images, SVG for icons).
  3. Save them in `assets/images/` or `assets/icons/`.
  4. Register the new asset in `lib/core/constants/app_assets.dart`.
- **Imports**: Mention and import widgets and assets in the main screen file.

## 3. ♿ Accessibility & Semantics
- **Rule**: Every UI component MUST be wrapped with a `Semantics` widget **AS THE FIRST (OUTERMOST) WRAPPER** in the main screen file.
  - *Correct*: `Semantics(label: '...', child: Center(child: MyWidget()))`
  - *Incorrect*: `Center(child: Semantics(label: '...', child: MyWidget()))`
- **Label**: Provide a concise, meaningful description in the `label` property.

## 4. 📦 Imports & Formatting
- **Rule**: ALWAYS use **Package Imports** (e.g., `import 'package:tahseen/...'`) instead of relative imports (e.g., `import '../../...'`).
- **Standard**: This ensures consistency and prevents issues with nested file structures.

## 5. 🚀 Post-Generation Tasks
- **Rule**: Before finishing any screen or feature generation task, you MUST run the route generator script:
  - `dart run lib/core/tools/create_auto_files/route_generator_data.dart`
- **Purpose**: This automatically generates/updates the `route.gr.dart` file and registers the new pages with AutoRouter.

## 6. 🌍 Localization & Theme Reminder
- **Localization**: Use `generate_key.dart` for ALL strings and access them via `'key'.tr()`.
- **Theming**: Use `AppColors` and `AppTextStyles` for all styling. NO hardcoded values.

---
*Failure to extract widgets or wrap them in Semantics is a violation of the Tahseen Professional Standard.*
