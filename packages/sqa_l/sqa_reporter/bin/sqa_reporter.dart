/// The command line:
///
///   dart run sqa_reporter [--input <file>] [--output <dir>]
///                         [--format playwright|patrol-log]
///                         [--platform web|android|ios]
///                         [--utc-offset -05:00]
library;

import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';

void main(List<String> argv) {
  final _Args args = _Args.parse(argv);

  if (args.offset == null) {
    stderr.writeln('Unreadable --utc-offset. Give it as -05:00, +02:00 or 0.');
    exitCode = 2;
    return;
  }

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

  // No staleness warning here on purpose. Rebuilding from results already on
  // disk is what `melos run sqaWeb` is *for*, so a warning on that path cries
  // wolf on every deliberate use — and any stderr line reads as an error in
  // the melos output. The fact still matters, so the report carries it: the
  // page says when the run finished as well as when it was generated.
  // The offset is not only how the times are printed: it is also what a
  // timestamp with no zone means, and Patrol writes every one of its own
  // without a zone. Reading and printing on the same clock is what makes the
  // report show the time the device showed.
  final ParsedRun run = args.format == 'playwright'
      ? parsePlaywright(input, zone: args.offset!)
      : parsePatrolLog(input, zone: args.offset!);
  final int written = writeSerenityResults(
    run,
    Directory(args.output),
    platform: args.platform,
  );
  final File index = writeDashboard(
    run,
    Directory(args.output),
    platform: args.platform,
    offset: args.offset!,
  );
  final List<File> pages = writeTestPages(
    run,
    Directory(args.output),
    platform: args.platform,
    offset: args.offset!,
  );
  final List<File> galleries = writeScreenshotPages(
    run,
    Directory(args.output),
    platform: args.platform,
    offset: args.offset!,
  );
  final List<File> features = writeFeaturePages(
    run,
    Directory(args.output),
    platform: args.platform,
    offset: args.offset!,
  );
  final List<File> tags = writeTagPages(
    run,
    Directory(args.output),
    platform: args.platform,
    offset: args.offset!,
  );

  stdout
    ..writeln(
      'Wrote $written SQA Reporter result(s) to ${args.output} '
      '(${args.platform})',
    )
    ..writeln(
      'Dashboard: ${index.path} (${pages.length} test page(s), '
      '${galleries.length} gallery page(s), '
      '${features.length} feature page(s), '
      '${tags.length} tag page(s))',
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
    required this.offset,
  });

  factory _Args.parse(List<String> argv) {
    String? input;
    String? output;
    String? format;
    String? platform;
    String? rawOffset;
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
        case '--utc-offset':
          rawOffset = argv[i + 1];
      }
    }
    final String root = _repoRoot();
    input ??= '$root/build/e2e/web/playwright/results.json';
    // A Playwright report is JSON; a device log is not. Guessing from the
    // extension keeps the common cases flag-free.
    format ??= input.endsWith('.json') ? 'playwright' : 'patrol-log';
    platform ??= format == 'playwright' ? 'web' : 'android';
    // One directory holds the whole thing — the JSON results, the screenshots
    // and the pages that read them — so publishing the report is copying one
    // folder, and deleting it cannot leave half a report behind.
    output ??= '$root/build/e2e/$platform/sqa_reporter/report';
    return _Args(
      input: input,
      output: output,
      format: format,
      platform: platform,
      // Unset means the pages' own default clock, which is the one the suite
      // runs on. The report's *name* has no such flag: it is derived from the
      // platform, so two reports of the same suite are never named differently
      // by two projects.
      offset: rawOffset == null ? reportOffset : parseOffset(rawOffset),
    );
  }

  final String input;
  final String output;
  final String format;
  final String platform;

  /// The clock the report is drawn on: both what a timestamp with no zone
  /// means when it is read, and how every time is printed. Null means
  /// `--utc-offset` was given but could not be read.
  final Duration? offset;
}

/// The repo root, found by walking up to the directory that holds `.git`
/// rather than by counting `..` segments — the same rule the shell scripts
/// already follow, for the same reason: this tree
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
