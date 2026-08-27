/// E2E Test Reporter: turns a Patrol run into report results.
///
/// Three layers, kept apart on purpose:
///
///  * the **model** (`model.dart`) — what a run *was*, owing nothing to any
///    output format;
///  * the **inputs** (`inputs.dart`, `markers.dart`) — one adapter per
///    transport, both producing the model;
///  * the **serialiser** (`results_writer.dart`) — writes the JSON results
///    from the model. A second output format is a second serialiser, not a
///    rewrite;
///  * the **site** (`site/`) — the HTML report over the same model, all of
///    its markup and assets authored here (see `site_assets.dart` for where
///    the clean-room line runs).
library;

export 'src/inputs.dart' show parsePatrolLog, parsePlaywright, splitTitle;
export 'src/markers.dart'
    show
        MarkerParse,
        epochOfStamp,
        hasStepWith,
        parseMarkers,
        promoteStatus,
        stripAnsi;
export 'src/model.dart';
export 'src/requirements.dart'
    show RequirementNode, featuresIn, requirementsOf, resultSeverity;
export 'src/results_writer.dart'
    show
        Capture,
        capturesOf,
        completeNameOf,
        htmlReportName,
        isoUtc,
        presentedStepsOf,
        prune,
        reportDigest,
        reportFileName,
        resultName,
        shotNamesFor,
        slugOf,
        stepDescription,
        widenedBoundsOf,
        writeResults;
export 'src/site/charts.dart'
    show
        chartLabels,
        chartLegend,
        chartOrder,
        donutChart,
        durationChart,
        niceAxis,
        outcomesChart;
export 'src/site/dashboard.dart'
    show
        compoundDuration,
        dashboardHtml,
        escapeHtml,
        projectTitleFor,
        resultIcon,
        severityLabel,
        severityWeight,
        writeDashboard;
export 'src/site/features_page.dart'
    show featurePageHtml, featureReportName, featuresHtml, writeFeaturePages;
export 'src/site/page_chrome.dart'
    show offsetLabel, parseOffset, reportOffset, timestampOf;
export 'src/site/screenshots_page.dart'
    show screenshotsPageHtml, screenshotsReportName, writeScreenshotPages;
export 'src/site/site_assets.dart'
    show platformMark, resultColors, resultGlyphs;
export 'src/site/tags_page.dart'
    show tagPageHtml, tagReportName, tagsOf, writeTagPages;
export 'src/site/test_page.dart' show testPageHtml, writeTestPages;
