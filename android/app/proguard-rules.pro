# HotelPro Security Hardening - ProGuard & R8 Obfuscation Rules
# Protects against reverse-engineering, decompilation, and code tampering

# Flutter Core Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve JNI / Native Callbacks
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve Serialization / Deserialization Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Razorpay Payment Gateway SDK Protection
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class com.google.android.gms.auth.api.phone.** { *; }
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Supabase / OkHttp / WebSockets
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Kotlin Coroutines & Reflection
-dontwarn kotlinx.coroutines.**
-keepclassmembers class * extends kotlin.coroutines.jvm.internal.ContinuationImpl {
    int label;
}

# AndroidX & Google Play Core
-dontwarn androidx.**
-dontwarn android.support.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep FileProvider for in-app APK installer
-keep class androidx.core.content.FileProvider { *; }

# Security Hardening: Strip Android Log outputs in release builds to prevent credential/data leakage
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}

# Stacktrace preservation
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

