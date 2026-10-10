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

# Preserve Serialization / Deserialization
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-dontwarn androidx.**
-dontwarn android.support.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Stacktrace preservation
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
