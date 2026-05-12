<div align="center">

# 🌍 Localization Automation Suite
### Flutter ARB Tools — Automate your translations, eliminate manual errors.

[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-l10n-54C5F8?logo=flutter&logoColor=white)](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)]()

</div>

---

## 🤔 The Problem

Traditional Flutter localization is **manual and error-prone**:

```
❌ Dev edits app_en.arb
❌ Dev forgets to add same key to app_ar.arb
❌ Team uses wrong or inconsistent key names
❌ Dead keys pile up as features change
❌ Product managers can't touch translation files directly
```

---

## ✅ The Solution

This suite **automates the entire localization lifecycle** in 4 tools:

```
📋 Google Sheets / Excel  ──►  CSV  ──►  .arb files   (csv_to_arb)
🔄 EN ↔ AR comparison     ──►  Report + auto-fix       (sync_languages)
🗑  Unused key detection   ──►  Report + auto-delete    (detect_unused_keys)
🔑 Text → snake_case key  ──►  "Login Title" → login_title (generate_key)
```

---

## 📁 File Structure

```
lib/core/tools/localization/
├── main_localization.dart      ← 🎮 Interactive menu & CLI entry-point
├── csv_to_arb.dart             ← 📋 CSV / Excel → .arb converter
├── sync_languages.dart         ← 🔄 Language sync & missing-key fixer
├── detect_unused_keys.dart     ← 🗑  Dead key scanner & cleaner
├── generate_key.dart           ← 🔑 Auto key generator (text → snake_case)
├── auto_translate.dart         ← 🤖 Auto translates missing CSV keys (LibreTranslate)
└── sample_translations.csv     ← 📄 Demo CSV to get started
```

---

## 🚀 Quick Start

### Option A — Interactive Menu (recommended)

```bash
dart run lib/core/tools/localization/main_localization.dart
```

You'll see:

```
╔══════════════════════════════════════════════════════╗
║       🌍  Localization Automation Suite 🌍          ║
║              Flutter ARB Tools — Tahseen             ║
╚══════════════════════════════════════════════════════╝

Options:
  1  📋  CSV → ARB
  2  🔄  Sync Languages
  3  🗑   Detect Unused Keys
  4  🔑  Generate Key
  5  ⚡  Run Full Pipeline
  6  🤖  Auto-Translate CSV (via LibreTranslate)
  0  🚪  Exit
```

### Option B — Direct CLI

```bash
# One-liner: CSV → sync → unused report
dart run lib/core/tools/localization/main_localization.dart all translations.csv
```

---

## 📖 Tool Reference

### 📋 1. CSV → ARB  (`csv_to_arb.dart`)

Converts a CSV file (exported from Excel or Google Sheets) into `.arb` files.

**CSV Format:**
```csv
key,en,ar
login_title,Login,تسجيل الدخول
logout_btn,Logout,تسجيل الخروج
,Forgot Password?,نسيت كلمة المرور؟   ← key is auto-generated!
```

> 💡 Leave the `key` column blank — the script generates it from the English text automatically.
> `"Forgot Password?"` → `forgot_password`

**Usage:**
```bash
dart run lib/core/tools/localization/main_localization.dart csv <csv_path> [output_dir]

# Example
dart run lib/core/tools/localization/main_localization.dart csv translations.csv lib/l10n
```

**Output:**
```
📂 Reading CSV: translations.csv
🌍 Detected languages: en, ar
✅ Written 17 keys → lib/l10n/app_en.arb
✅ Written 17 keys → lib/l10n/app_ar.arb
🔑 Auto-generated 1 key(s) from text.
🎉 Done!
```

> ✅ Supports **any number of languages** — just add more columns: `key,en,ar,fr,de,...`

---

### 🔄 2. Sync Languages  (`sync_languages.dart`)

Compares all `.arb` files against a reference locale and reports divergences.

```bash
# Report only
dart run lib/core/tools/localization/main_localization.dart sync lib/l10n

# Auto-add missing keys + sort all files
dart run lib/core/tools/localization/main_localization.dart sync lib/l10n --fix --sort

# Use French as reference
dart run lib/core/tools/localization/main_localization.dart sync lib/l10n --ref=fr
```

| Flag | Effect |
|------|--------|
| `--fix` | Adds missing keys as empty strings so translators can fill them in |
| `--sort` | Sorts all `.arb` files alphabetically |
| `--ref=<locale>` | Reference locale (default: `en`) |

**Sample output:**
```
🔍 Reference locale: en  (24 keys)
────────────────────────────────────────────
📦 Locale: ar
  ❌ Missing in ar (2):
       - login_title
       - logout_btn
  ⚠️  Extra in ar (1):
       + old_key_123
💡 Run with --fix to automatically add missing keys.
```

---

### 🗑 3. Detect Unused Keys  (`detect_unused_keys.dart`)

Scans every `.dart` file in `lib/` and finds ARB keys that are **never referenced** in code.

```bash
# Report only
dart run lib/core/tools/localization/main_localization.dart unused lib/l10n

# Delete unused keys from all .arb files (with confirmation prompt)
dart run lib/core/tools/localization/main_localization.dart unused lib/l10n --delete

# CI mode: no prompt
dart run lib/core/tools/localization/main_localization.dart unused lib/l10n --delete --yes
```

**How it works:**

The scanner checks for both `snake_case` and `camelCase` variants so it catches all common patterns:

```dart
context.l10n.loginTitle       // camelCase ✅ detected
S.of(context).login_title     // snake_case ✅ detected
AppLocalizations.of(ctx).loginTitle  // ✅ detected
```

**Sample output:**
```
🔑 Loaded 24 keys from app_en.arb
🔍 Scanning lib/ for key usages...

✅ Used keys   : 10
🗑  Unused keys : 14
   - cancel_btn
   - old_feature_label
   - ...

📄 Report saved → unused_arb_keys_report.txt
```

---

### 🔑 4. Generate Key  (`generate_key.dart`)

Converts any human text into a valid ARB `snake_case` key.

```bash
dart run lib/core/tools/localization/main_localization.dart key "Login Screen Title"
# 🔑 Generated key: login_screen_title

dart run lib/core/tools/localization/main_localization.dart key "Enter Your Email!"
# 🔑 Generated key: enter_your_email

```

---

### ⚡ 5. Full Pipeline  (`all` command)

Runs **everything** in the correct sequence in one shot:

```bash
dart run lib/core/tools/localization/main_localization.dart all translations.csv
```

```
1️⃣  CSV → ARB           (csv_to_arb)
2️⃣  Sync + fix + sort   (sync_languages --fix --sort)
3️⃣  Unused key report   (detect_unused_keys)
✅  Full pipeline complete!
```

---

### 🤖 6. Auto-Translate CSV (`auto_translate.dart`)

Automatically translates any empty values in your CSV file using the open-source [LibreTranslate](https://docs.libretranslate.com) API.

**How it works:**
1. Reads `sample_translations.csv`.
2. Identifies the source language (first column after key) and target languages.
3. Finds empty translation cells and queries the LibreTranslate API to fill them.
4. Saves the completed translations back to the CSV.

**Usage:**
```bash
dart run lib/core/tools/localization/auto_translate.dart
```

> **🐳 Docker Note (Recommended for Production):**
> The script defaults to a public LibreTranslate instance. To avoid IP bans (rate limits) and protect your app's data privacy, it is highly recommended to host LibreTranslate locally via Docker:
> ```bash
> docker run -ti --rm -p 5000:5000 libretranslate/libretranslate
> ```
> Then update the `apiUrl` in `auto_translate.dart` to `http://localhost:5000/translate`.

---

## 🔧 Flutter Setup

After generating your `.arb` files, wire Flutter's built-in gen-l10n:

**`pubspec.yaml`**
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true
```

**`l10n.yaml`** (project root)
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

Then run:
```bash
flutter gen-l10n
```

And use in your app:
```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MyHomePage(),
);

// Access translations
Text(context.l10n.loginTitle)
```

---

## 🧩 Recommended Workflow

```
1. Product team edits Google Sheets
      ↓
2. Export → File → Download → CSV
      ↓
3. dart run ... all translations.csv
      ↓   ┌─ CSV → ARB
      ↓   ├─ Sync EN ↔ AR (auto-fix)
      ↓   └─ Unused keys report
      ↓
4. flutter gen-l10n
      ↓
5. ✅ Ship
```

---

## 📊 Comparison

| Task               | Before                         | After                                 |
|--------------------|--------------------------------|---------------------------------------|
| Add new key        |  Edit 2+ `.arb` files manually | Add row in Google Sheets → run `all`  |
| Check sync         | Manual review                  | `sync` command — instant report       |
| Clean dead keys    | Never done / guesswork         | `unused --delete` — automated         |
| Key naming         | Inconsistent across team       | `generate_key` — always snake_case    |
| Onboard translator | Send raw `.arb` JSON           | Send Google Sheets link               |

---

## ❓ FAQ

### Q1 — Where should translation data live: `assets/` or `lib/`?

**Short answer: `lib/l10n/` with `.arb` files is best for most apps.**

|                            | `lib/l10n/` + ARB                          | `assets/translations/` + JSON |
|----------------------------|--------------------------------------------|-------------------------------|
| **Type-safe access**       | ✅ Compile-time error on wrong key          | ❌ Runtime crash               |
| **IDE autocomplete**       | ✅ Full                                     | ❌ None                        |
| **Performance**            | ✅ Zero runtime overhead (compiled to Dart) | ⚠️ File read on startup       |
| **OTA updates**            | ❌ Needs app update                         | ✅ Update without releasing    |
| **Pluralization / Gender** | ✅ Built-in ICU support                     | ❌ Manual implementation       |
| **Flutter gen-l10n**       | ✅ Official tooling                         | ❌ Needs 3rd-party package     |
| **Translator-friendly**    | ✅ (via this suite → CSV)                   | ✅                             |

**When to choose each approach:**

```
lib/l10n/ + ARB      → 99% of apps ✅  (static UI strings, type-safe)
assets/ + JSON       → Need OTA translation updates without Play Store release
Hybrid (both)        → Large apps: static UI in lib/l10n, dynamic content in assets/
```

> **For Tahseen:** use `lib/l10n/` + ARB.
> The `.arb` files are compiled to Dart at build time — **zero file-read overhead at runtime**.
> All automation tools in this suite are built around this approach.

---

### Q2 — What is `.arb` and why not use `.json`?

**ARB = Application Resource Bundle** — a format designed by Google specifically for Flutter/Dart localization.

Structurally, `.arb` **is valid JSON**, but the file extension tells Flutter tooling to treat it as a localization resource and generate type-safe Dart code from it.

```json
// app_en.arb  — looks like JSON, but has special powers
{
  "@@locale": "en",
  "loginTitle": "Login",
  "welcomeMsg": "Hello, {name}! You have {count} messages.",
  "@welcomeMsg": {
    "description": "Home screen greeting",
    "placeholders": {
      "name": { "type": "String", "example": "Ahmed" },
      "count": { "type": "int" }
    }
  }
}
```

Flutter auto-generates this from the `.arb`:
```dart
// Compile-time error if you pass wrong type — impossible with plain JSON
context.l10n.welcomeMsg(name: "Ahmed", count: 5)
// → "Hello, Ahmed! You have 5 messages."
```

**What you lose by renaming to `.json`:**

| Feature | `.arb` | `.json` |
|---------|--------|---------|
| `flutter gen-l10n` support | ✅ Works automatically | ❌ Not recognized |
| Type-safe Dart code generation | ✅ | ❌ |
| Placeholders `{name}` | ✅ With type checking | ❌ Manual string replace |
| Pluralization `{count, plural, one{item} other{items}}` | ✅ ICU standard | ❌ Not built-in |
| Gender `{gender, select, male{he} female{she}}` | ✅ | ❌ |
| `@key` metadata / descriptions | ✅ | ❌ |
| IDE localization support | ✅ VS Code + IntelliJ | Plain JSON only |

**Pluralization example — only possible with `.arb`:**
```json
{
  "itemCount": "{count, plural, =0{No items} =1{One item} other{{count} items}}",
  "@itemCount": {
    "placeholders": { "count": { "type": "int" } }
  }
}
```
```dart
context.l10n.itemCount(0)   // → "No items"
context.l10n.itemCount(1)   // → "One item"
context.l10n.itemCount(42)  // → "42 items"
```

> **Bottom line:** `.arb` = `.json` syntax + Flutter superpowers.
> Renaming to `.json` gives you nothing and breaks everything.

---

<div align="center">

**Built with ❤️ for the Tahseen Flutter project**

*Part of the `lib/core/tools/` automation toolkit*

</div>
