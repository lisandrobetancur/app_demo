plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.demo.market_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.demo.market_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol runs the Dart suite through its own instrumentation runner.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    // The orchestrator is not optional here, and not just for a clean state.
    // Patrol enumerates the Dart tests and asks the native side to run them
    // one at a time, but a Dart test bundle runs every test the moment it is
    // started. Without a fresh process per test case, the first request runs
    // the whole bundle and the remaining five find nothing left to execute —
    // which shows up as 1 passed, 5 failed.
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    // Installing the orchestrator APK times out on slower devices with the
    // default limit, which surfaces as an opaque
    // `ShellCommandUnresponsiveException` rather than as a timeout.
    installation {
        timeOutInMs = 10 * 60 * 1000
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
