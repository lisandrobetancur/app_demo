/// The requirements tree: what the run says about the product, rather than
/// about the tests.
///
/// Two levels, epic → feature, taken from what `scenario()` declares. The
/// reference derives its hierarchy from a directory structure and names the
/// levels by depth (a two-level tree is feature → story there); here the
/// declaration *is* the structure, so the levels are named for what the suite
/// already calls them, and the third level the reference would add is absent
/// on purpose — this repository dropped `story` because, declared one-to-one
/// with its tests, it was a second name for each of them.
///
/// Coverage is computed here and stored nowhere, which is also what the
/// reference does: a requirement's tests are the ones tagged with it or with
/// anything beneath it, counted at render time.
library;

import 'markers.dart';
import 'model.dart';
import 'serenity_writer.dart';

/// Severity order, worst first: a requirement reports the worst verdict among
/// its tests, so a green feature really means nothing under it went wrong.
const List<String> resultSeverity = <String>[
  'FAILURE',
  'ERROR',
  'SKIPPED',
  'UNDEFINED',
  'SUCCESS',
];

/// One node of the tree: an epic, or a feature under it.
class RequirementNode {
  RequirementNode({
    required this.name,
    required this.type,
    List<RequirementNode>? children,
    List<RunCase>? cases,
  }) : children = children ?? <RequirementNode>[],
       cases = cases ?? <RunCase>[];

  /// As declared: `Access`, `Authentication`.
  final String name;

  /// `epic` or `feature`.
  final String type;

  final List<RequirementNode> children;

  /// The tests declared directly against this requirement. Only features hold
  /// them; an epic's tests are its features'.
  final List<RunCase> cases;

  /// Path-safe name, and the stem of this requirement's page.
  String get slug => slugOf(name);

  /// Every test under this requirement, its descendants included.
  List<RunCase> get allCases => <RunCase>[
    ...cases,
    for (final RequirementNode child in children) ...child.allCases,
  ];

  /// How many tests ended in each verdict, descendants included.
  Map<String, int> get counts {
    final Map<String, int> tally = <String, int>{};
    for (final RunCase testCase in allCases) {
      final String result =
          serenityResult[promoteStatus(testCase.status, testCase.steps)]!;
      tally[result] = (tally[result] ?? 0) + 1;
    }
    return tally;
  }

  int get testCount => allCases.length;

  /// Passing tests over all of them, as a percentage. A requirement nobody
  /// tested has no rate rather than a rate of zero — the distinction the
  /// reference draws by showing such rows as pending.
  double? get passRate {
    final int total = testCount;
    if (total == 0) {
      return null;
    }
    return (counts['SUCCESS'] ?? 0) * 100 / total;
  }

  /// The worst verdict under this requirement, or `UNDEFINED` when it holds
  /// no tests at all.
  String get result {
    final Map<String, int> tally = counts;
    for (final String candidate in resultSeverity) {
      if ((tally[candidate] ?? 0) > 0) {
        return candidate;
      }
    }
    return 'UNDEFINED';
  }
}

/// Builds the tree from a run: epics in declared-name order, each holding its
/// features, and any feature that declared no epic standing at the root
/// rather than being filed under an invented one.
List<RequirementNode> requirementsOf(ParsedRun run) {
  final Map<String, RequirementNode> epics = <String, RequirementNode>{};
  final Map<String, RequirementNode> features = <String, RequirementNode>{};
  final List<RequirementNode> roots = <RequirementNode>[];

  for (final RunCase testCase in run.cases) {
    final String? epicName = testCase.meta?.epic;
    final String featureName = testCase.meta?.feature ?? testCase.suite;
    final String featureKey = '${epicName ?? ''}/$featureName';

    final RequirementNode feature = features.putIfAbsent(featureKey, () {
      final RequirementNode created = RequirementNode(
        name: featureName,
        type: 'feature',
      );
      if (epicName == null) {
        roots.add(created);
      } else {
        final RequirementNode epic = epics.putIfAbsent(epicName, () {
          final RequirementNode parent = RequirementNode(
            name: epicName,
            type: 'epic',
          );
          roots.add(parent);
          return parent;
        });
        epic.children.add(created);
      }
      return created;
    });
    feature.cases.add(testCase);
  }

  for (final RequirementNode root in roots) {
    root.children.sort(
      (RequirementNode a, RequirementNode b) => a.name.compareTo(b.name),
    );
  }
  roots.sort((RequirementNode a, RequirementNode b) {
    // Epics first, then the features that belong to none: the tree reads
    // top-down before it reads alphabetically.
    if (a.type != b.type) {
      return a.type == 'epic' ? -1 : 1;
    }
    return a.name.compareTo(b.name);
  });
  return roots;
}

/// Every feature in the tree, in the order the pages list them.
List<RequirementNode> featuresIn(List<RequirementNode> roots) =>
    <RequirementNode>[
      for (final RequirementNode root in roots)
        if (root.type == 'feature') root else ...root.children,
    ];
