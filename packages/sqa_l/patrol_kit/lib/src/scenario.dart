import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'taxonomy.dart';

/// Business metadata and case data, for the report.
///
/// A report that lists `purchase_flow_test` and `login_test` tells a reader
/// which files ran. It does not tell them which *features* are covered, which
/// failures matter most, or with what data a case ran — which is what anyone
/// outside the team actually opens a report to find out.
///
/// Both helpers print a marker that the report generator picks up from the
/// test's stdout, the same channel the steps and screenshots already travel
/// through. Nothing here touches the app.

/// How much a failure of this scenario matters.
///
/// The four levels the report's severity filter offers, so a severity works without
/// translation.
enum Severity {
  blocker,
  critical,
  normal,
  minor,
  trivial;

  String get label => name;
}

const String _metaMarker = 'PATROL_META';
const String _paramMarker = 'PATROL_PARAM';

/// Declares what a test covers, in business terms.
///
/// Call it as the first line of a `patrolTest` body:
///
/// ```dart
/// scenario(
///   feature: Features.checkout,
///   severity: Severity.blocker,
/// );
/// ```
///
/// [feature] is what the report groups by on its Features page, which reads by
/// functionality instead of by file, and the epic above it comes with the
/// feature — declared once in the project's catalogue rather than repeated at
/// every scenario. See [Feature] for why that pairing lives there.
///
/// [epic] overrides it, for the rare case of a feature that genuinely belongs
/// somewhere else in one particular run. Reach for it knowing that a feature
/// filed under two epics is two rows in the report.
///
/// There is deliberately no `story`. The taxonomy this borrows from offers one, but a story
/// is a unit of work while a test is a unit of verification: the level pays
/// for itself only when one story holds several tests. Declared one-to-one
/// with the tests, as it was here, it is a second name for each of them and
/// groups nothing. The test's own name is the leaf. If a project ever has real
/// stories — several tests to one — adding the parameter back is one line and
/// breaks no caller.
void scenario({
  required Feature feature,
  Epic? epic,
  Severity severity = Severity.normal,
  String? description,
}) {
  _emit(_metaMarker, <String, String>{
    'epic': (epic ?? feature.epic).name,
    'feature': feature.name,
    'severity': severity.label,
    if (description != null) 'description': description,
  });
}

/// Records a piece of data the case ran with, so it can be reproduced from
/// the report alone.
///
/// ```dart
/// testParam('User', TestData.demoEmail);
/// testParam('Coupon', TestData.validCoupon);
/// ```
void testParam(String name, Object? value) {
  _emit(_paramMarker, <String, String>{'name': name, 'value': '$value'});
}

/// Markers travel as one-line JSON, like Patrol's own `PATROL_LOG`, so a
/// value containing the `|` separator cannot corrupt the stream.
void _emit(String marker, Map<String, String> payload) {
  debugPrintSynchronously('$marker ${jsonEncode(payload)}');
}
