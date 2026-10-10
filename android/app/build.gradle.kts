import java.util.Base64
import java.net.URLDecoder
import java.nio.charset.StandardCharsets

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Multi-App Dynamic Packaging & Naming Resolution ────────────────────────
// Resolves distinct App Name & Application Package ID for each role APK
// (Staff Waiter, Delivery Rider, Housekeeping, Manager MIS, Customer Dining)
val targetProp = (project.findProperty("target") as? String ?: "").lowercase().replace("\\", "/")
val targetAppProp = (project.findProperty("targetApp") as? String ?: "").lowercase()
val customAppName = project.findProperty("appName") as? String
val customAppId = project.findProperty("appId") as? String

// Check dart-defines if passed via --dart-define
var dartDefinesAppName: String? = null
var dartDefinesAppId: String? = null
val dartDefinesProp = project.findProperty("dart-defines") as? String
if (!dartDefinesProp.isNullOrEmpty()) {
    try {
        val decoded = String(Base64.getDecoder().decode(dartDefinesProp), StandardCharsets.UTF_8)
        decoded.split(",").forEach { pair ->
            val parts = pair.split("=")
            if (parts.size == 2) {
                val key = URLDecoder.decode(parts[0], "UTF-8")
                val value = URLDecoder.decode(parts[1], "UTF-8")
                if (key.equals("APP_NAME", ignoreCase = true)) dartDefinesAppName = value
                if (key.equals("APP_ID", ignoreCase = true)) dartDefinesAppId = value
            }
        }
    } catch (_: Exception) {}
}

val (resolvedAppId, resolvedAppName) = when {
    targetAppProp == "waiter" || targetAppProp.contains("waiter") || targetProp.contains("waiter") || dartDefinesAppId == "waiter" -> {
        "com.isecuresystem.hotelpro.waiter" to "HotelPro Waiter POS"
    }
    targetAppProp == "delivery" || targetAppProp == "delivery_boy" || targetAppProp == "rider" || targetAppProp.contains("delivery") || targetAppProp.contains("rider") || targetProp.contains("delivery") || targetProp.contains("rider") || dartDefinesAppId == "delivery" || dartDefinesAppId == "rider" || dartDefinesAppId == "delivery_boy" -> {
        "com.isecuresystem.hotelpro.delivery" to "HotelPro Delivery Boy"
    }
    targetAppProp == "housekeeping" || targetAppProp.contains("housekeeping") || targetProp.contains("housekeeping") || dartDefinesAppId == "housekeeping" -> {
        "com.isecuresystem.hotelpro.housekeeping" to "HotelPro Housekeeping"
    }
    targetAppProp == "manager" || targetAppProp == "mis" || targetAppProp.contains("manager") || targetProp.contains("manager") || targetProp.contains("mis") || dartDefinesAppId == "manager" || dartDefinesAppId == "mis" -> {
        "com.isecuresystem.hotelpro.manager" to "HotelPro Manager MIS"
    }
    targetAppProp == "customer" || targetAppProp == "dining" || targetAppProp.contains("customer") || targetProp.contains("customer") || targetProp.contains("dining") || dartDefinesAppId == "customer" || dartDefinesAppId == "dining" -> {
        "com.isecuresystem.hotelpro.customer" to "HotelPro Customer Dining"
    }
    else -> {
        "com.isecuresystem.hotelpro" to "Hotelpro Management System"
    }
}

val finalAppId = if (!customAppId.isNullOrEmpty() && customAppId.contains(".")) {
    customAppId
} else if (!dartDefinesAppId.isNullOrEmpty() && dartDefinesAppId!!.contains(".")) {
    dartDefinesAppId!!
} else {
    resolvedAppId
}

val finalAppName = if (!customAppName.isNullOrEmpty()) {
    customAppName
} else if (!dartDefinesAppName.isNullOrEmpty()) {
    dartDefinesAppName!!
} else {
    resolvedAppName
}

println("=================================================================")
println("[HotelPro Gradle] Target: '$targetProp'")
println("[HotelPro Gradle] TargetApp: '$targetAppProp'")
println("[HotelPro Gradle] dartDefines: AppId='$dartDefinesAppId', AppName='$dartDefinesAppName'")
println("[HotelPro Gradle] RESOLVED -> AppId: '$finalAppId' | AppName: '$finalAppName'")
println("=================================================================")

android {
    namespace = "com.example.hotelpro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Dynamic package ID ensures all apps can be installed side-by-side
        applicationId = finalAppId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AndroidManifest.xml uses ${appName} as android:label
        manifestPlaceholders["appName"] = finalAppName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
