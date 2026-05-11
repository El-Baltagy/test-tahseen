// lib/utils/form_auto_scroll.dart
import 'package:flutter/material.dart';

extension FormAutoScroll on GlobalKey<FormState> {
  /// Validates the form and, if invalid, scrolls to the first invalid field.
  ///
  /// - [context]  is required to call `Scrollable.ensureVisible`.
  /// - [listRecorder] must be a list of `(GlobalKey<FormFieldState>, FocusNode?)` records in the visual/tab order
  ///   so the helper can find the first invalid field and request focus.
  /// - [duration] and [curve] control the scroll animation.
  /// - [alignment] controls where the field will be positioned in the viewport (0.0 top, 0.5 center, 1.0 bottom).
  /// Returns `true` if the form is valid, `false` otherwise.
  Future<bool> validateAndScroll(
      BuildContext context, {
        required List<(GlobalKey<FormFieldState>, FocusNode?)> listRecorder,
        Duration duration = const Duration(milliseconds: 300),
        Curve curve = Curves.easeInOut,
        double alignment = 0.1,
      }) async {
    final formState = currentState;
    if (formState == null) {
      // No form attached to this key.
      return false;
    }

    // Run full form validation first.
    final isValid = formState.validate();
    if (isValid) return true;

    // Find the first field that reports an error.
    for (final record in listRecorder) {
      final key = record.$1;
      final focus = record.$2;
      final fieldState = key.currentState;
      if (fieldState == null) continue;

      // If the field has an error after validation, scroll to it.
      // `hasError` is true when validator returned a non-null string.
      final hasError = (fieldState).hasError;
      if (hasError) {
        final ctx = key.currentContext;
        if (ctx != null) {
          // Give the UI a frame to settle before scrolling.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await Scrollable.ensureVisible(
            ctx,
            duration: duration,
            curve: curve,
            alignment: alignment,
          );

          // Optionally request focus if a FocusNode was provided.
          if (focus != null) {
            focus.requestFocus();
          } else {
            // Try to focus the field's focusable descendant if possible.
            final focusable = Focus.maybeOf(ctx);
            if (focusable != null) {
              focusable.requestFocus();
            }
          }
        }
        break;
      }
    }

    return false;
  }
}


// class ExampleFormPage extends StatefulWidget {
//   const ExampleFormPage({Key? key}) : super(key: key);
//
//   @override
//   State<ExampleFormPage> createState() => _ExampleFormPageState();
// }

// class _ExampleFormPageState extends State<ExampleFormPage> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//
//   // Keys for each field (preserve order)
//   final GlobalKey<FormFieldState<String>> _nameKey = GlobalKey<FormFieldState<String>>();
//   final GlobalKey<FormFieldState<String>> _emailKey = GlobalKey<FormFieldState<String>>();
//   final GlobalKey<FormFieldState<String>> _passwordKey = GlobalKey<FormFieldState<String>>();
//
//   // Optional focus nodes to focus the field after scrolling
//   final FocusNode _nameFocus = FocusNode();
//   final FocusNode _emailFocus = FocusNode();
//   final FocusNode _passwordFocus = FocusNode();
//
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void dispose() {
//     _nameFocus.dispose();
//     _emailFocus.dispose();
//     _passwordFocus.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _onSubmit() async {
//     final valid = await _formKey.validateAndScroll(
//       context,
//       listRecorder: [
//         (_nameKey, _nameFocus),
//         (_emailKey, _emailFocus),
//         (_passwordKey, _passwordFocus),
//       ],
//       // optional: adjust alignment so field appears a bit below top
//       alignment: 0.15,
//     );
//
//     if (valid) {
//       // proceed with submission
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form valid!')));
//     } else {
//       // invalid: the extension already scrolled to the first invalid field
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fix errors')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Form AutoScroll Example')),
//       body: SingleChildScrollView(
//         controller: _scrollController,
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const SizedBox(height: 24),
//               TextFormField(
//                 key: _nameKey,
//                 focusNode: _nameFocus,
//                 decoration: const InputDecoration(labelText: 'Name'),
//                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
//               ),
//               const SizedBox(height: 24),
//               TextFormField(
//                 key: _emailKey,
//                 focusNode: _emailFocus,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return 'Email is required';
//                   final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
//                   return emailRegex.hasMatch(v) ? null : 'Enter a valid email';
//                 },
//               ),
//               const SizedBox(height: 24),
//               // Add some vertical space to simulate long forms
//               for (var i = 0; i < 6; i++) const SizedBox(height: 24),
//               TextFormField(
//                 key: _passwordKey,
//                 focusNode: _passwordFocus,
//                 decoration: const InputDecoration(labelText: 'Password'),
//                 obscureText: true,
//                 validator: (v) => (v != null && v.length >= 6) ? null : 'Password must be 6+ chars',
//               ),
//               const SizedBox(height: 40),
//               ElevatedButton(
//                 onPressed: _onSubmit,
//                 child: const Text('Submit'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
