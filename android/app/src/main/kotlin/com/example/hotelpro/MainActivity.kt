package com.example.hotelpro

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.isecuresystem.hotelpro/installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCacheDir" -> {
                    try {
                        val cacheDir = context.externalCacheDir ?: context.cacheDir
                        result.success(cacheDir.absolutePath)
                    } catch (e: Exception) {
                        result.success(context.cacheDir.absolutePath)
                    }
                }
                "getAppVersion" -> {
                    try {
                        val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            context.packageManager.getPackageInfo(
                                context.packageName,
                                PackageManager.PackageInfoFlags.of(0)
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            context.packageManager.getPackageInfo(context.packageName, 0)
                        }
                        result.success(pInfo.versionName ?: "")
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.localizedMessage, null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "filePath parameter is null or empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val srcFile = File(filePath)
                        if (!srcFile.exists() || srcFile.length() == 0L) {
                            result.error("FILE_NOT_FOUND", "APK file does not exist or is empty at: $filePath", null)
                            return@setMethodCallHandler
                        }

                        // Ensure target file is inside standard cache folder for full FileProvider compatibility
                        val targetCacheDir = context.externalCacheDir ?: context.cacheDir
                        val installFile: File = try {
                            if (!srcFile.canonicalPath.startsWith(targetCacheDir.canonicalPath)) {
                                val destFile = File(targetCacheDir, srcFile.name)
                                srcFile.copyTo(destFile, overwrite = true)
                                destFile
                            } else {
                                srcFile
                            }
                        } catch (_: Exception) {
                            srcFile
                        }

                        // Ensure file is readable
                        installFile.setReadable(true, false)

                        val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                installFile
                            )
                        } else {
                            Uri.fromFile(installFile)
                        }

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }

                        // Explicitly grant read URI permissions across target activities (Samsung, Xiaomi, Vivo, Pixel)
                        try {
                            val resInfoList = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                context.packageManager.queryIntentActivities(
                                    intent,
                                    PackageManager.ResolveInfoFlags.of(0)
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                context.packageManager.queryIntentActivities(intent, 0)
                            }
                            for (resolveInfo in resInfoList) {
                                val pkgName = resolveInfo.activityInfo.packageName
                                context.grantUriPermission(pkgName, apkUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }

                            // Grant to common system package installer packages
                            val installerPackages = listOf(
                                "com.google.android.packageinstaller",
                                "com.android.packageinstaller",
                                "com.samsung.android.packageinstaller"
                            )
                            for (pkg in installerPackages) {
                                try {
                                    context.grantUriPermission(pkg, apkUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                } catch (_: Exception) {}
                            }
                        } catch (_: Exception) {}

                        // Launch package installer
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (se: SecurityException) {
                            // On Android 8.0+, if installing unknown apps is disabled, open settings
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val settingsIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                    data = Uri.parse("package:${context.packageName}")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(settingsIntent)
                                result.error("PERMISSION_DENIED", "Please allow 'Install unknown apps' permission in Settings and try again.", null)
                            } else {
                                throw se
                            }
                        }
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.localizedMessage ?: "Unknown installation error", e.stackTraceToString())
                    }
                }
                "setSecureScreen" -> {
                    try {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        activity?.runOnUiThread {
                            if (enabled) {
                                activity?.window?.setFlags(
                                    WindowManager.LayoutParams.FLAG_SECURE,
                                    WindowManager.LayoutParams.FLAG_SECURE
                                )
                            } else {
                                activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SECURE_SCREEN_ERROR", e.localizedMessage, null)
                    }
                }
                "isDeviceRooted" -> {
                    try {
                        val isRooted = checkDeviceRootStatus()
                        result.success(isRooted)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkDeviceRootStatus(): Boolean {
        try {
            val buildTags = Build.TAGS
            if (buildTags != null && buildTags.contains("test-keys")) {
                return true
            }

            val paths = arrayOf(
                "/system/app/Superuser.apk",
                "/sbin/su",
                "/system/bin/su",
                "/system/xbin/su",
                "/data/local/xbin/su",
                "/data/local/bin/su",
                "/system/sd/xbin/su",
                "/system/bin/failsafe/su",
                "/data/local/su"
            )
            for (path in paths) {
                if (File(path).exists()) return true
            }
        } catch (_: Exception) {}
        return false
    }
}

