/// The command line, mirroring the Allure converter's flags so the two can be
/// run side by side on the same input while they coexist:
///
///   dart run sqa_reporter [--input <file>] [--output <dir>]
///                         [--format playwright|patrol-log]
///                         [--platform web|android|ios]
///                         [--title "E2E test report web"]
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
  final ParsedRun run = args.format == 'playwright'
      ? parsePlaywright(input)
      : parsePatrolLog(input);
  final int written = writeSerenityResults(
    run,
    Directory(args.output),
    platform: args.platform,
  );
  final File index = writeDashboard(
    run,
    Directory(args.output),
    platform: args.platform,
    title: args.title,
    offset: args.offset!,
  );
  final List<File> pages = writeTestPages(
    run,
    Directory(args.output),
    platform: args.platform,
    title: args.title,
    offset: args.offset!,
  );
  final List<File> galleries = writeScreenshotPages(
    run,
    Directory(args.output),
    platform: args.platform,
    title: args.title,
    offset: args.offset!,
  );
  final List<File> requirements = writeRequirementPages(
    run,
    Directory(args.output),
    platform: args.platform,
    title: args.title,
    offset: args.offset!,
  );
  final List<File> tags = writeTagPages(
    run,
    Directory(args.output),
    platform: args.platform,
    title: args.title,
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
      '${requirements.length} requirement page(s), '
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
    required this.title,
    required this.offset,
  });

  factory _Args.parse(List<String> argv) {
    String? input;
    String? output;
    String? format;
    String? platform;
    String? title;
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
        case '--title':
          title = argv[i + 1];
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
      // Left null on purpose when not given: the pages fall back to the
      // platform's own wording, so the default lives in one place.
      title: title,
      // Same rule for the clock: unset means the pages' own default, which
      // is the one the suite runs on.
      offset: rawOffset == null ? reportOffset : parseOffset(rawOffset),
    );
  }

  final String input;
  final String output;
  final String format;
  final String platform;

  /// What the banner says this report is of. Null means the default for the
  /// platform.
  final String? title;

  /// The clock the pages show their times in. Null means `--utc-offset` was
  /// given but could not be read.
  final Duration? offset;
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
