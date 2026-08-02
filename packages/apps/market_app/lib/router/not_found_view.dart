import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:empty_state/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fallback for unknown routes: a deep link to a nonexistent resource shows
/// this view, never a blank screen.
class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  static const Key viewKey = Key('shell_not_found_view');

  @override
  Widget build(BuildContext context) => Scaffold(
    key: viewKey,
    body: SafeArea(
      child: EmptyState(
        icon: AppIcons.warning,
        title: 'shell.not_found.title'.tr(),
        message: 'shell.not_found.message'.tr(),
        actionLabel: 'shell.not_found.go_home_button'.tr(),
        onAction: () => GoRouter.of(context).go('/dashboard'),
      ),
    ),
  );
}
