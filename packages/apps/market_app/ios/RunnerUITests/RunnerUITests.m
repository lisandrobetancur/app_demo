//
//  Native entry point for the Patrol suite on iOS.
//
//  iOS cannot run Dart tests directly: it runs an XCUITest, and this bundle is
//  the bridge — the exact counterpart of MainActivityTest.java on Android.
//  The macro below writes the class: at runtime it asks the running app which
//  Dart tests exist and adds one Objective-C method per test, so a Dart test
//  that fails shows up as a failed Xcode test rather than being buried inside
//  one opaque case.
//
//  THE TARGET MATTERS AS MUCH AS THE FILE. `patrol test` ends in
//
//      xcodebuild test-without-building -only-testing RunnerUITests/RunnerUITests
//
//  so the bundle has to be a target named exactly RunnerUITests, of type
//  com.apple.product-type.bundle.ui-testing, and it has to be in the Runner
//  scheme's test action. Without it xcodebuild exits 70 — a configuration
//  error, not a test failure — after building the app perfectly well, which is
//  how this cost a green build eight minutes of Xcode before saying anything.
//
//  The file mirrors the template shipped with the patrol package; nothing in
//  it is specific to this app.
//
@import XCTest;
@import patrol;
@import ObjectiveC.runtime;

PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
