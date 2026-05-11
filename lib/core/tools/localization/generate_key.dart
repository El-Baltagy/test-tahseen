// ─────────────────────────────────────────────────────────────────────────────
// generate_key.dart
// Converts human-readable text into a valid ARB key (snake_case).
//
// Usage (standalone):
//   dart run lib/core/tools/localization/generate_key.dart "Login Screen Title"
//
// Output: login_screen_title
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run generate_key.dart "Login Screen Title"');
    exit(1);
  }
  final input = args.join(' ');
  final key = generateKey(input);
  print('🔑 Generated key: $key');
}

/// Converts any human-readable string into a valid ARB snake_case key.
///
/// Examples:
///   "Login Screen Title"  → login_screen_title
///   "Enter Your Email!"   → enter_your_email
///   "2FA Code"            → _2fa_code
String generateKey(String text) {
  return text
      .trim()
      // Replace any non-alphanumeric (except spaces) with space
      .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
      // Collapse multiple spaces
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase()
      // Remove leading digits (ARB keys must start with letter or _)
      .replaceFirstMapped(RegExp(r'^(\d)'), (m) => '_${m.group(1)}')
      // Remove trailing underscores
      .replaceAll(RegExp(r'_+$'), '');
}
