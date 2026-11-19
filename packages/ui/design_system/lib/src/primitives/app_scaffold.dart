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
    this.semanticsId,
    this.titleSemanticsId,
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

  /// Identifier of the whole view for black-box automation — the element a
  /// test waits for to know the screen is up. See [AppButton.semanticsId].
  final String? semanticsId;

  /// Identifier of the app bar's [title] text. See [AppButton.semanticsId].
  final String? titleSemanticsId;

  @override
  Widget build(BuildContext context) {
    final Widget scaffold = _buildScaffold();
    if (semanticsId == null) {
      return scaffold;
    }
    // A node of its own (`container`) so the identifier has somewhere to land,
    // and `explicitChildNodes` so the view's texts and controls keep their own
    // nodes instead of being merged into this one.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      identifier: semanticsId,
      child: scaffold,
    );
  }

  Widget _buildScaffold() {
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
              title: titleWidget ?? (title == null ? null : _titleText()),
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

  Widget _titleText() {
    final Widget text = Text(title!);
    if (titleSemanticsId == null) {
      return text;
    }
    return Semantics(identifier: titleSemanticsId, child: text);
  }
}
