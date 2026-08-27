# ── Flutter ────────────────────────────────────────────────────────────────────
# Flutter's own ProGuard rules are injected by the Flutter Gradle plugin.
# The rules below cover third-party libraries used by this project.

# ── Firebase ───────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Supabase / Ktor / OkHttp ───────────────────────────────────────────────────
-keep class io.ktor.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn io.ktor.**
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Google Sign-In ─────────────────────────────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }

# ── Gson / JSON (used internally by some SDKs) ─────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# ── Kotlin coroutines ──────────────────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# ── Hive (local storage) ───────────────────────────────────────────────────────
-keep class com.hivedb.** { *; }

# ── Preserve line number information for crash reporting ───────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
