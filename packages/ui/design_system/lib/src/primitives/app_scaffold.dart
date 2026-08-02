import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Standard page scaffold.
///
/// Adds, on top of the Material [Scaffold]: SafeArea, default page padding,
/// optional automatic scrolling and — on wide layouts — a centered
/// max-width container so the same view works on mobile and web.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.scrollable = true,
    this.padding = AppSpacing.pagePadding,
    this.floatingActionButton,
    this.bottomBar,
    this.onRefresh,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;
  final Widget? bottomBar;

  /// When set on a scrollable body, wraps it in a [RefreshIndicator].
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: body);
    if (scrollable) {
      content = SingleChildScrollView(
        physics: onRefresh == null
            ? null
            : const AlwaysScrollableScrollPhysics(),
        child: content,
      );
      if (onRefresh != null) {
        content = RefreshIndicator(onRefresh: onRefresh!, child: content);
      }
    }
    final bool hasAppBar =
        title != null || titleWidget != null || actions != null;
    return Scaffold(
      appBar: hasAppBar
          ? AppBar(
              title: titleWidget ?? (title == null ? null : Text(title!)),
              actions: actions,
              leading: leading,
            )
          : null,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
