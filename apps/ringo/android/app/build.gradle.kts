plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ringo.ringo"
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
        applicationId = "com.ringo.ringo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    sourceSets {
        getByName("main").jniLibs.srcDir(
            layout.buildDirectory.dir("generated/ringoSleepCore/jniLibs"),
        )
    }
}

val ringoSleepCoreDirectory = rootProject.file("../../../native/ringo_sleep_core")
val ringoSleepCoreOutput = layout.buildDirectory.dir("generated/ringoSleepCore/jniLibs")

val buildRingoSleepCore by tasks.registering(Exec::class) {
    group = "build"
    description = "Builds the Rust sleep-analysis core for Android ABIs."
    workingDir(ringoSleepCoreDirectory)
    inputs.dir(ringoSleepCoreDirectory)
    outputs.dir(ringoSleepCoreOutput)
    commandLine(
        "cargo",
        "ndk",
        "-t", "arm64-v8a",
        "-t", "armeabi-v7a",
        "-t", "x86_64",
        "-o", ringoSleepCoreOutput.get().asFile.absolutePath,
        "build",
        "--release",
    )
}

tasks.named("preBuild") {
    dependsOn(buildRingoSleepCore)
}

flutter {
    source = "../.."
}
