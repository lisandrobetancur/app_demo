/// SQA Reporter: turns a Patrol run into report results.
///
/// Three layers, kept apart on purpose:
///
///  * the **model** (`model.dart`) — what a run *was*, owing nothing to any
///    output format;
///  * the **inputs** (`inputs.dart`, `markers.dart`) — one adapter per
///    transport, both producing the model;
///  * the **serialiser** (`serenity_writer.dart`) — writes Serenity-schema
///    JSON from the model. A second output format is a second serialiser,
///    not a rewrite;
///  * the **site** (`site/`) — the HTML report over the same model, all of
///    its markup and assets authored here (see `site_assets.dart` for where
///    the clean-room line runs).
library;

export 'src/inputs.dart' show parsePatrolLog, parsePlaywright, splitTitle;
export 'src/markers.dart'
    show MarkerParse, hasStepWith, parseMarkers, promoteStatus, stripAnsi;
export 'src/model.dart';
export 'src/serenity_writer.dart'
    show
        completeNameOf,
        isoUtc,
        prune,
        reportFileName,
        serenityResult,
        slugOf,
        writeSerenityResults;
export 'src/site/dashboard.dart'
    show
        compoundDuration,
        dashboardHtml,
        escapeHtml,
        projectTitleFor,
        resultIcon,
        writeDashboard;
export 'src/site/site_assets.dart' show resultColors, resultGlyphs;
