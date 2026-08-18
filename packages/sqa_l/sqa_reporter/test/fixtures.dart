/// Fixtures shaped exactly like the two transports deliver them, marker by
/// marker — the formats are the ones `patrol_to_allure.mjs` parses in
/// production, so both consumers of the stream are tested against the same
/// contract.
library;

import 'dart:convert';

/// A 1×1 transparent PNG, the smallest real image that decodes.
const String tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// The stdout of a passing test: scenario metadata, params, tags, one
/// business step holding one interaction and one assertion, two screenshots
/// (one whole, one chunked in two), and a trace with an info and a warn line.
String passingStdout() {
  final String chunk1 = tinyPngBase64.substring(0, tinyPngBase64.length ~/ 2);
  final String chunk2 = tinyPngBase64.substring(tinyPngBase64.length ~/ 2);
  return <String>[
    'PATROL_META ${jsonEncode(<String, String>{'epic': 'Access', 'feature': 'Authentication', 'severity': 'blocker', 'description': 'The door to everything else.'})}',
    'PATROL_PARAM ${jsonEncode(<String, String>{'name': 'User', 'value': 'ana@market.demo'})}',
    'PATROL_TAGS ${jsonEncode(<String>['smoke_test', 'success'])}',
    'PATROL_STEP|begin|1|Log in as the demo user',
    // A capture that fits in one chunk: the other shape of the marker.
    'PATROL_SHOT|before_login|0|1|$tinyPngBase64',
    'PATROL_LOG ${jsonEncode(<String, String>{'type': 'step', 'timestamp': '2026-08-18T10:00:01.000Z', 'action': 'tap login_submit_button', 'status': 'start'})}',
    'PATROL_LOG ${jsonEncode(<String, String>{'type': 'step', 'timestamp': '2026-08-18T10:00:02.500Z', 'action': 'tap login_submit_button', 'status': 'success'})}',
    'PATROL_ASSERT ${jsonEncode(<String, String>{'name': 'the dashboard greets the user', 'status': 'passed', 'expected': 'Hola, Ana', 'actual': 'Hola, Ana'})}',
    'PATROL_SHOT|after_login|0|2|$chunk1',
    'PATROL_STEP|end|1|passed',
    // The last chunk lands just after the step closed — the ownership rule
    // the parser exists to get right.
    'PATROL_SHOT|after_login|1|2|$chunk2',
    'PATROL_TRACE ${jsonEncode(<String, Object>{'at': '10:00:02', 'level': 'info', 'message': 'Signed in'})}',
    'PATROL_TRACE ${jsonEncode(<String, Object>{'at': '10:00:03', 'level': 'warn', 'message': 'Coupon already applied'})}',
  ].join('\n');
}

/// The stdout of a test that died on a locator: a business step whose
/// interaction never closed. The transport says "failed"; the tree knows it
/// was broken.
String brokenStdout() => <String>[
  'PATROL_STEP|begin|1|Open the catalog',
  'PATROL_LOG ${jsonEncode(<String, String>{'type': 'step', 'timestamp': '2026-08-18T10:01:00.000Z', 'action': 'tap missing_button', 'status': 'start'})}',
  'PATROL_STEP|end|1|broken',
].join('\n');

/// A Playwright report holding both tests, the shape `--format playwright`
/// consumes.
String playwrightReport() => jsonEncode(<String, Object>{
  'config': <String, Object>{'workers': 1},
  'stats': <String, Object>{'startTime': '2026-08-18T10:00:00.000Z'},
  'suites': <Object>[
    <String, Object>{
      'specs': <Object>[
        <String, Object>{
          'title': 'login_test logs in with the seeded demo account',
          'tests': <Object>[
            <String, Object>{
              'results': <Object>[
                <String, Object>{
                  'status': 'passed',
                  'startTime': '2026-08-18T10:00:00.500Z',
                  'duration': 2600,
                  'workerIndex': 0,
                  'retry': 0,
                  'stdout': <Object>[
                    <String, String>{'text': passingStdout()},
                  ],
                },
              ],
            },
          ],
        },
        <String, Object>{
          'title': 'catalog_test opens the catalog',
          'tests': <Object>[
            <String, Object>{
              'results': <Object>[
                <String, Object>{
                  'status': 'failed',
                  'startTime': '2026-08-18T10:00:59.000Z',
                  'duration': 1500,
                  'workerIndex': 0,
                  'retry': 0,
                  'stdout': <Object>[
                    <String, String>{'text': brokenStdout()},
                  ],
                  'errors': <Object>[
                    <String, String>{
                      'message':
                          'StateError: No text under missing_button — '
                          'wrong locator?',
                      'stack':
                          'StateError: No text under missing_button\n'
                          '#0  UiElement.text (element.dart:68)',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  ],
});

/// A device log holding one passing test between `type: "test"` boundaries,
/// with device noise before, between and after — the shape `--format
/// patrol-log` consumes.
String patrolLog() => <String>[
  '08-18 10:00:00.000  1234  5678 I flutter : device noise before',
  'PATROL_LOG ${jsonEncode(<String, String>{'type': 'test', 'status': 'start', 'name': 'login_test logs in with the seeded demo account', 'timestamp': '2026-08-18T10:00:00.500Z'})}',
  passingStdout(),
  'PATROL_LOG ${jsonEncode(<String, String>{'type': 'test', 'status': 'success', 'name': 'login_test logs in with the seeded demo account', 'timestamp': '2026-08-18T10:00:03.100Z'})}',
  '08-18 10:00:04.000  1234  5678 I flutter : device noise after',
].join('\n');
