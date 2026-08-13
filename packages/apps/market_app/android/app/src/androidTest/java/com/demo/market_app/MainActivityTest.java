package com.demo.market_app;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import pl.leancode.patrol.PatrolJUnitRunner;

/**
 * Native entry point for the Patrol suite on Android.
 *
 * Android cannot run Dart tests directly: it runs an instrumentation test,
 * and this class is the bridge. {@code listDartTests()} asks the running app
 * which Dart tests exist, JUnit turns each one into a separate test case, and
 * {@code runDartTest} executes it — so a Dart test that fails shows up as a
 * failed Android test rather than being buried inside one opaque case.
 *
 * The file mirrors the template shipped with the patrol package; the only
 * thing specific to this app is the package name and {@code MainActivity}.
 */
@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
