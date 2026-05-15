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
- **Theming & Typography**: 
  - ALWAYS use `AppTextStyles` from `lib/core/theming/app_text_styles.dart`.
  - **Rule**: NEVER define `TextStyle` properties (fontSize, color, fontWeight, etc.) directly in the widget.
  - **Adjustment**: If a slight change is needed (e.g., custom color), use `.copyWith()` on an existing `AppTextStyle`.
  - *Example*: `style: AppTextStyles.font16SemiBold.copyWith(color: AppColors.primaryGoldStart)`
- **Colors**: Use `AppColors` for all color values. NO hardcoded HEX or basic colors.

## 7. 📏 Spacing & Padding System
- **Rule**: NEVER use raw `SizedBox` for vertical or horizontal spacing.
- **Extensions**: Use the custom extensions from `lib/core/extension/double.dart`:
  - *Vertical Space*: `10.verticalSpace`
  - *Horizontal Space*: `10.horizontalSpace`
- **Padding & Sizes**: 
  - Use constant values for all Padding, Margins, and fixed Sizes. 
  - **Standard**: These should be defined as constants (e.g., `AppPadding.p16`, `AppSizes.s10`). 
  - Avoid using "Magic Numbers" (e.g., `EdgeInsets.all(12)`); use `EdgeInsets.all(AppPadding.p12)` instead.

## 8. ⚡ Performance & Widgets
- **Const Constructors**: ALWAYS use `const` for widgets and constructors whenever possible to optimize rebuilds.
- **Small Widgets**: Break down large build methods into small, focused `StatelessWidget` files. 
- **Rule**: A single build method should ideally not exceed 100 lines. If it does, extract sub-widgets.

## 9. 🛠️ Error Handling & Cubit Logic
- **BaseCubit**: Use `BaseCubit` or a standard error handling pattern to manage network failures, unauthorized access, or server errors.
- **UI Feedback**: Handle errors in `BlocListener` and show appropriate feedback (SnackBar or Dialog) using project-standard utilities.

## 10. 📝 Documentation & Comments
- **Rule**: Every function with complex logic must have a concise one-line comment above it explaining its purpose.
- **Clean Code**: Code should be self-documenting through clear variable and function names, but critical logic requires explicit comments.

---
*Failure to extract widgets, use constant values, or wrap them in Semantics is a violation of the Tahseen Professional Standard.*
