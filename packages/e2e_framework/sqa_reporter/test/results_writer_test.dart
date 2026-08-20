import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The conformance suite: the written JSON against the schema, rule by rule —
/// required fields, the serialisation conventions, the result vocabulary, file
/// naming and the step tree's shape.
///
/// There is no specification document to consult: this file *is* it. A change
/// to the schema that these tests still pass is a change nobody agreed to.
void main() {
  late Directory out;
  late File inputFile;
  late Map<String, Object?> passing;
  late Map<String, Object?> broken;
  late List<File> jsonFiles;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('sqa_reporter_test');
    inputFile = File('${out.path}/results.json')
      ..writeAsStringSync(playwrightReport());
    final ParsedRun run = parsePlaywright(inputFile);
    final int written = writeResults(
      run,
      Directory('${out.path}/results'),
      platform: 'web',
    );
    expect(written, 2);
    jsonFiles = Directory('${out.path}/results')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.json'))
        .toList();
    final List<Map<String, Object?>> outcomes = jsonFiles
        .map(
          (File f) => jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
        )
        .toList();
    passing = outcomes.singleWhere(
      (Map<String, Object?> o) => o['result'] == 'SUCCESS',
    );
    broken = outcomes.singleWhere(
      (Map<String, Object?> o) => o['result'] != 'SUCCESS',
    );
  });

  tearDownAll(() => out.deleteSync(recursive: true));

  group('file naming', () {
    test(
      'is sha256(storyTitle:name).json, so artefacts of one test pair up',
      () {
        final String expected = sha256
            .convert(
              utf8.encode(
                'Authentication:logs in with the seeded demo account',
              ),
            )
            .toString();
        expect(
          jsonFiles.map((File f) => f.uri.pathSegments.last),
          contains('$expected.json'),
        );
      },
    );
  });

  group('the adapter rules, recursively', () {
    test('no nulls and no empty collections anywhere', () {
      void walk(Object? value, String path) {
        expect(value, isNotNull, reason: 'null at $path');
        if (value is Map<String, Object?>) {
          expect(value, isNotEmpty, reason: 'empty map at $path');
          value.forEach(
            (String key, Object? child) => walk(child, '$path.$key'),
          );
        } else if (value is List<Object?>) {
          expect(value, isNotEmpty, reason: 'empty list at $path');
          for (int i = 0; i < value.length; i += 1) {
            walk(value[i], '$path[$i]');
          }
        }
      }

      walk(passing, r'$');
      walk(broken, r'$');
    });

    test('primitives survive pruning even when falsy', () {
      expect(passing['manual'], false);
      expect(passing['isManualTestingUpToDate'], false);
    });

    test('dates are ISO-8601 UTC instants', () {
      final RegExp iso = RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$',
      );
      expect('${passing['startTime']}', matches(iso));
      expect('${passing['testRunTimestamp']}', matches(iso));
    });
  });

  group('the required and computed fields', () {
    test('id and name are present and non-empty', () {
      for (final Map<String, Object?> outcome in <Map<String, Object?>>[
        passing,
        broken,
      ]) {
        expect('${outcome['id']}', isNotEmpty);
        expect('${outcome['name']}', isNotEmpty);
      }
    });

    test('result uses the vocabulary the pages read', () {
      const Set<String> vocabulary = <String>{
        'SUCCESS',
        'FAILURE',
        'ERROR',
        'SKIPPED',
        'UNDEFINED',
      };
      expect(vocabulary, contains(passing['result']));
      expect(vocabulary, contains(broken['result']));
    });

    test('durationInSeconds is duration over one thousand', () {
      final int duration = passing['duration']! as int;
      expect(passing['durationInSeconds'], duration / 1000);
    });

    test('testData carries what the case declared it ran with', () {
      expect(passing['testData'], 'User=ana@market.demo');
    });
  });

  group('the step tree', () {
    test('numbers steps with one global counter and tracks depth', () {
      final List<Object?> steps = passing['testSteps']! as List<Object?>;
      final List<int> numbers = <int>[];
      void walk(List<Object?> list, int level) {
        for (final Object? raw in list) {
          final Map<String, Object?> step = raw! as Map<String, Object?>;
          numbers.add(step['number']! as int);
          expect(step['level'], level);
          if (step['children'] != null) {
            walk(step['children']! as List<Object?>, level + 1);
          }
        }
      }

      walk(steps, 0);
      expect(
        numbers,
        List<int>.generate(numbers.length, (int i) => i + 1),
        reason: 'the step number is a sequence across the whole test',
      );
    });

    test('a screenshot is referenced by bare name and exists on disk', () {
      final List<Object?> steps = passing['testSteps']! as List<Object?>;
      final Map<String, Object?> business =
          steps.first! as Map<String, Object?>;
      final List<Object?> shots = business['screenshots']! as List<Object?>;
      expect(shots, hasLength(2));
      for (final Object? raw in shots) {
        final Map<String, Object?> shot = raw! as Map<String, Object?>;
        final String name = shot['screenshot']! as String;
        expect(
          name,
          isNot(contains('/')),
          reason: 'File serialiser: bare name',
        );
        expect(File('${out.path}/results/$name').existsSync(), isTrue);
        expect(shot['timeStamp'], isA<int>());
      }
    });

    test('an assertion folds expected/actual into its description (G2)', () {
      final List<Object?> steps = passing['testSteps']! as List<Object?>;
      final Map<String, Object?> business =
          steps.first! as Map<String, Object?>;
      final List<Object?> children = business['children']! as List<Object?>;
      final Map<String, Object?> assertion =
          children.last! as Map<String, Object?>;
      expect('${assertion['description']}', contains('verified: Hola, Ana'));
    });

    test('carries no run log: what mattered in it is already a step', () {
      final List<Object?> steps = passing['testSteps']! as List<Object?>;
      for (final Object? raw in steps) {
        expect((raw! as Map<String, Object?>)['reportData'], isNull);
      }
      // The warn line is not lost — it is a step of its own, which is what
      // made the log itself redundant.
      expect(
        steps
            .map(
              (Object? s) => '${(s! as Map<String, Object?>)['description']}',
            )
            .join('\n'),
        contains('Coupon already applied'),
      );
    });
  });

  group('the requirements link', () {
    test('userStory carries the epic/feature path, two levels deep', () {
      final Map<String, Object?> story =
          passing['userStory']! as Map<String, Object?>;
      expect(story['path'], 'access/authentication');
      expect(story['type'], 'feature');
      expect((story['pathElements']! as List<Object?>).length, 2);
    });

    test('featureTag nests parent/child by name, for the rollup', () {
      final Map<String, Object?> tag =
          passing['featureTag']! as Map<String, Object?>;
      expect(tag['name'], 'Access/Authentication');
      expect(tag['displayName'], 'Authentication');
    });

    test('tags include epic, severity, context and the declared tags', () {
      final List<Object?> tags = passing['tags']! as List<Object?>;
      final Set<String> types = tags
          .map((Object? t) => '${(t! as Map<String, Object?>)['type']}')
          .toSet();
      expect(
        types,
        containsAll(<String>['epic', 'feature', 'severity', 'context', 'tag']),
      );
    });
  });

  group('the failing test', () {
    test('is promoted to ERROR: its only casualty was a locator', () {
      expect(broken['result'], 'ERROR');
    });

    test('carries the failure cause with the parsed error type (G1)', () {
      final Map<String, Object?> cause =
          broken['testFailureCause']! as Map<String, Object?>;
      expect(cause['errorType'], 'StateError');
      expect('${cause['message']}', contains('missing_button'));
      expect(broken['testFailureClassname'], 'StateError');
    });
  });
}
