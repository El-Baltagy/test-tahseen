# 🤖 AI Technical Command: Project Architecture Rules

> [!IMPORTANT]
> This is a **STRICT** protocol for any AI model interacting with this codebase. You must follow these rules without deviation. Do **NOT** propose alternative patterns or add personal preferences.

## 1. 🎨 Figma Data Extraction (Theming & Assets)
When extracting design data (Colors, Fonts, Assets) from Figma:
- **Colors**: Must be added to `lib/core/theming/app_colors.dart`.
- **Text Styles**: Must be added to `lib/core/theming/app_text_styles.dart`.
- **Assets**: Must be registered in `lib/core/constants/app_assets.dart`.
- **Rule**: NO hardcoded Hex codes or String paths in UI widgets. Use the constants from the paths above.

## 2. 🌍 String Localization & Generation
NEVER hardcode strings in the UI. For every new string:
1. **Script**: Execute `dart run lib/core/tools/localization/generate_key.dart "<English Text>"`.
2. **Action**: This script generates a `snake_case` key and appends it to `assets/l10n/translations.csv`.
3. **Usage**: In the code, use the generated key followed by `.tr()`. 
   - *Example*: `'hello_world'.tr()`

## 3. 🏗️ Feature & Screen Generation
To create any new feature or screen:
1. **Script**: Use `dart run lib/core/tools/create_auto_files/main_script.dart <FeatureName>`.
2. **Behavior**: 
   - This creates the structure in `lib/features/screens/<FeatureName>`.
   - It will prompt for **Cubit** or **Notifier** (Assume Cubit/Y unless specified).
   - It automatically registers routes and runs `build_runner`.
3. **Rule**: Do NOT manually create folders or files for screens. Always use this script.

## ⚠️ Core Constraints for AI
- **NO Hardcoding**: Every value must come from a centralized constant or localization key.
- **Script Fidelity**: Follow the logic of the project's tools (`generate_key.dart`, `main_script.dart`) exactly as written.
- **Zero Opinion**: Do not add extra widgets, packages, or architectural layers from your own view. Stick to the project's established pattern.
- **Uncertainty**: If a path is missing or a script fails, **STOP** and ask the user for clarification before proceeding.

---
*Follow these instructions to maintain a professional, consistent, and automated codebase.*
