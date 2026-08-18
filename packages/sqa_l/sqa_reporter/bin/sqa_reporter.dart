/// The command line, mirroring the Allure converter's flags so the two can be
/// run side by side on the same input while they coexist:
///
///   dart run sqa_reporter [--input <file>] [--output <dir>]
///                         [--format playwright|patrol-log]
///                         [--platform web|android|ios]
library;

import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';

void main(List<String> argv) {
  final _Args args = _Args.parse(argv);

  final File input = File(args.input);
  if (!input.existsSync()) {
    stderr
      ..writeln(
        'No ${args.format == 'playwright' ? 'Playwright results' : 'device log'}'
        ' at ${args.input}',
      )
      ..writeln('Run the suite first:')
      ..writeln(
        args.format == 'playwright'
            ? '  melos run e2eWeb'
            : '  melos run e2eAndroid',
      );
    exitCode = 1;
    return;
  }

  // A report is only as fresh as the run it was built from, and nothing else
  // makes that visible: the output is stamped with generation time, not run
  // time. Warn when the input is old enough to belong to an earlier run.
  final int ageMinutes = DateTime.now()
      .difference(input.lastModifiedSync())
      .inMinutes;
  if (ageMinutes >= 10) {
    stderr.writeln(
      'WARNING: ${args.input} is $ageMinutes minutes old — this report will '
      'describe that run, not a newer one. Re-run the suite first.',
    );
  }

  final ParsedRun run = args.format == 'playwright'
      ? parsePlaywright(input)
      : parsePatrolLog(input);
  final int written = writeSerenityResults(
    run,
    Directory(args.output),
    platform: args.platform,
  );

  stdout.writeln(
    'Wrote $written SQA Reporter result(s) to ${args.output} '
    '(${args.platform})',
  );
  if (written == 0) {
    exitCode = 1;
  }
}

class _Args {
  _Args({
    required this.input,
    required this.output,
    required this.format,
    required this.platform,
  });

  factory _Args.parse(List<String> argv) {
    String? input;
    String? output;
    String? format;
    String? platform;
    for (int i = 0; i + 1 < argv.length; i += 2) {
      switch (argv[i]) {
        case '--input':
          input = argv[i + 1];
        case '--output':
          output = argv[i + 1];
        case '--format':
          format = argv[i + 1];
        case '--platform':
          platform = argv[i + 1];
      }
    }
    final String root = _repoRoot();
    input ??= '$root/build/e2e/web/playwright/results.json';
    // A Playwright report is JSON; a device log is not. Guessing from the
    // extension keeps the common cases flag-free.
    format ??= input.endsWith('.json') ? 'playwright' : 'patrol-log';
    platform ??= format == 'playwright' ? 'web' : 'android';
    output ??= '$root/build/e2e/$platform/sqa_reporter/results';
    return _Args(
      input: input,
      output: output,
      format: format,
      platform: platform,
    );
  }

  final String input;
  final String output;
  final String format;
  final String platform;
}

/// The repo root, found by walking up to the directory that holds `.git`
/// rather than by counting `..` segments — the same rule the shell scripts
/// and the Allure converter already follow, for the same reason: this tree
/// has moved before, and a hop count breaks in silence when it moves again.
String _repoRoot() {
  Directory dir = Directory.current;
  while (!Directory('${dir.path}${Platform.pathSeparator}.git').existsSync() &&
      !File('${dir.path}${Platform.pathSeparator}.git').existsSync()) {
    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path; // outside a repo: relative to cwd
    }
    dir = parent;
  }
  return dir.path;
}
