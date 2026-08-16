import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Business metadata and case data, for the report.
///
/// A report that lists `purchase_flow_test` and `login_test` tells a reader
/// which files ran. It does not tell them which *features* are covered, which
/// failures matter most, or with what data a case ran — which is what anyone
/// outside the team actually opens a report to find out.
///
/// Both helpers print a marker that the Allure converter picks up from the
/// test's stdout, the same channel the steps and screenshots already travel
/// through. Nothing here touches the app.

/// How much a failure of this scenario matters.
///
/// Mirrors Allure's own scale, so the report's severity filter works without
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
///   epic: 'Compra',
///   feature: 'Carrito y checkout',
///   story: 'Comprar un producto del catálogo',
///   severity: Severity.blocker,
/// );
/// ```
///
/// [epic], [feature] and [story] are what Allure groups by in its *Behaviors*
/// view, which reads by functionality instead of by file.
void scenario({
  required String epic,
  required String feature,
  required String story,
  Severity severity = Severity.normal,
  String? description,
}) {
  _emit(_metaMarker, <String, String>{
    'epic': epic,
    'feature': feature,
    'story': story,
    'severity': severity.label,
    if (description != null) 'description': description,
  });
}

/// Records a piece of data the case ran with, so it can be reproduced from
/// the report alone.
///
/// ```dart
/// testParam('Usuario', TestData.demoEmail);
/// testParam('Cupón', TestData.validCoupon);
/// ```
void testParam(String name, Object? value) {
  _emit(_paramMarker, <String, String>{
    'name': name,
    'value': '$value',
  });
}

/// Markers travel as one-line JSON, like Patrol's own `PATROL_LOG`, so a
/// value containing the `|` separator cannot corrupt the stream.
void _emit(String marker, Map<String, String> payload) {
  debugPrintSynchronously('$marker ${jsonEncode(payload)}');
}
