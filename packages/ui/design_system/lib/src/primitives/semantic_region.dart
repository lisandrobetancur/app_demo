import 'package:flutter/widgets.dart';

/// A part of the screen a black-box test addresses as a whole: a list, a
/// section, a loading / empty / error state, a dialog or sheet body.
///
/// It gets a semantics node of its own (`container`), so its [identifier] has
/// somewhere to land — Android's `resource-id`, iOS's
/// `accessibilityIdentifier`, web's `flt-semantics-identifier` — and
/// `explicitChildNodes`, so the texts and controls inside keep their own nodes
/// instead of being merged into this one. A test can then wait for the region,
/// and find what it holds inside it.
///
/// For a single control or text, put the identifier on that control instead;
/// see `AppButton.semanticsId` for where it has to go to reach its node.
class SemanticRegion extends StatelessWidget {
  const SemanticRegion({
    required this.identifier,
    required this.child,
    super.key,
  });

  final String identifier;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    identifier: identifier,
    child: child,
  );
}
