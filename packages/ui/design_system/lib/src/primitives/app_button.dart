import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Visual variants of [AppButton].
enum AppButtonVariant {
  primary,
  secondary,
  text,
  danger;

  bool get isPrimary => this == AppButtonVariant.primary;

  bool get isSecondary => this == AppButtonVariant.secondary;

  bool get isText => this == AppButtonVariant.text;

  bool get isDanger => this == AppButtonVariant.danger;
}

/// Standard button: adds loading state, optional icon and variant handling on
/// top of the themed Material buttons.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final Widget child = _AppButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
    );
    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.danger => ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: child,
      ),
    };
    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class _AppButtonContent extends StatelessWidget {
  const _AppButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label)),
      ],
    );
  }
}
