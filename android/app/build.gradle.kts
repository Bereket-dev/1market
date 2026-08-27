import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// ── Signing — read from key.properties (gitignored) ──────────────────────────
// Create android/key.properties with:
//   storeFile=<absolute-path-to-your.keystore>
//   storePassword=<keystore-password>
//   keyAlias=upload
//   keyPassword=<key-password>
//
// NEVER commit key.properties or the .keystore file to version control.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.jigjigamarket.koolan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.jigjigamarket.koolan"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Signing configs ───────────────────────────────────────────────────────
    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use upload key when key.properties exists; fall back to debug
            // so `flutter run --release` still works without a keystore.
            signingConfig = if (keyPropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // ── R8 / shrinking ───────────────────────────────────────────────
            isMinifyEnabled = true
            isShrinkResources = true

            // ProGuard rules — the default Flutter rules cover most cases.
            // Add project-specific keep rules in proguard-rules.pro.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Debug keeps minify off for fast builds.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Upload R8 mapping for Crashlytics deobfuscation when online.
    // Skip via android/gradle.properties: disableCrashlyticsMappingUpload=true
    firebaseCrashlytics {
        mappingFileUploadEnabled = !project.hasProperty("disableCrashlyticsMappingUpload")
    }
}

flutter {
    source = "../.."
}

// Sync client-safe keys from project-root .env → assets/config/local.env
tasks.register("syncLocalEnv") {
    doLast {
        exec {
            workingDir = rootProject.projectDir.parentFile
            commandLine("dart", "run", "tool/sync_local_env.dart")
        }
    }
}
tasks.configureEach {
    if (name == "preBuild") {
        dependsOn("syncLocalEnv")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
    implementation("com.google.firebase:firebase-analytics")
}
