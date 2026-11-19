import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standard text field: themed decoration plus label / error / counter
/// handling shared by every form in the app.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.semanticsId,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  /// Identifier for black-box automation: Android's `resource-id`, iOS's
  /// `accessibilityIdentifier` and web's `flt-semantics-identifier`. Lands on
  /// the editable node itself, the one that takes text input.
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final Widget field = _buildField();
    if (semanticsId == null) {
      return field;
    }
    // Around the field is right here, unlike AppButton: TextField's own
    // semantics node is the nearest one below, so the identifier merges into
    // the editable node (the one flagged as a text field), not a parent.
    return Semantics(identifier: semanticsId, child: field);
  }

  Widget _buildField() => TextField(
    controller: controller,
    enabled: enabled,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    maxLines: maxLines,
    autofillHints: autofillHints,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      helperText: helperText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon: suffix,
    ),
  );
}
