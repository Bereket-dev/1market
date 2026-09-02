pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropsFile = file("local.properties")
            if (localPropsFile.exists()) {
                localPropsFile.inputStream().use { properties.load(it) }
            }
            properties.getProperty("flutter.sdk")
                ?: System.getenv("FLUTTER_ROOT")
                ?: throw IllegalStateException(
                    "Flutter SDK not found. Set flutter.sdk in local.properties or the FLUTTER_ROOT env var."
                )
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.5.0" apply false
    id("com.google.firebase.crashlytics") version "3.0.3" apply false
}

include(":app")
