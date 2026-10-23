import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/core/components/app_update_dialog.dart';

enum AppTarget {
  windowsErp('Windows Desktop ERP', 'HotelPro_Windows_ERP.zip'),
  waiterPos('Waiter POS & Captain', 'HotelPro_WaiterPOS.apk'),
  deliveryBoy('Delivery Boy Partner', 'HotelPro_DeliveryBoy.apk'),
  housekeeping('Housekeeping & Inspection', 'HotelPro_Housekeeping.apk'),
  managerMis('Manager & Owner MIS', 'HotelPro_ManagerMIS.apk'),
  customerDining('Customer Food & Dining', 'HotelPro_CustomerDining.apk');

  final String displayName;
  final String releaseFileName;
  const AppTarget(this.displayName, this.releaseFileName);
}

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final String releasePageUrl;
  final bool hasUpdate;
  final DateTime? publishedAt;
  final AppTarget targetApp;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
    required this.hasUpdate,
    required this.targetApp,
    this.publishedAt,
  });
}

class AppUpdateService {
  static const String repoOwner = 'Sneckwiper98';
  static const String repoName = 'hotelpro';
  static const String baseInstalledVersion = '1.0.16';
  static String? _cachedDynamicVersion;

  /// Dynamically retrieves current installed version string (e.g. '1.0.11').
  /// Reads from local version.json manifest if present (updated by auto-updater),
  /// otherwise falls back to baseInstalledVersion.
  static String get currentInstalledVersion {
    if (_cachedDynamicVersion != null) return _cachedDynamicVersion!;

    if (!kIsWeb && Platform.isWindows) {
      try {
        // 1. Check in application directory
        final exePath = Platform.resolvedExecutable;
        final appDir = File(exePath).parent;
        final localVersionFile = File('${appDir.path}\\version.json');
        if (localVersionFile.existsSync()) {
          final content = localVersionFile.readAsStringSync();
          final data = jsonDecode(content);
          if (data is Map && data['version'] != null) {
            final v = data['version'].toString().replaceAll('v', '').trim();
            if (v.isNotEmpty) {
              _cachedDynamicVersion = v;
              return v;
            }
          }
        }

        // 2. Check in %APPDATA%\HotelPro\version.json
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final appDataVersionFile = File('$appData\\HotelPro\\version.json');
          if (appDataVersionFile.existsSync()) {
            final content = appDataVersionFile.readAsStringSync();
            final data = jsonDecode(content);
            if (data is Map && data['version'] != null) {
              final v = data['version'].toString().replaceAll('v', '').trim();
              if (v.isNotEmpty) {
                _cachedDynamicVersion = v;
                return v;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AppUpdateService] Error reading dynamic version: $e');
      }
    }

    _cachedDynamicVersion = baseInstalledVersion;
    return baseInstalledVersion;
  }

  /// Asynchronously fetches the exact installed version from the native Android PackageManager (if on Android),
  /// falling back to currentInstalledVersion.
  static Future<String> getInstalledVersionAsync() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final v = await _installerChannel.invokeMethod<String>('getAppVersion');
        if (v != null && v.trim().isNotEmpty) {
          final clean = v.replaceAll('v', '').trim();
          _cachedDynamicVersion = clean;
          return clean;
        }
      } catch (_) {}
    }
    return currentInstalledVersion;
  }

  /// Sets or updates the persisted version manifest
  static void saveInstalledVersion(String newVersion) {
    final clean = newVersion.replaceAll('v', '').trim();
    _cachedDynamicVersion = clean;

    if (!kIsWeb && Platform.isWindows) {
      try {
        final payload = jsonEncode({
          'version': clean,
          'updatedAt': DateTime.now().toIso8601String(),
          'product': 'HotelPro Enterprise Windows ERP',
        });

        // Save in app folder
        final exePath = Platform.resolvedExecutable;
        final appDir = File(exePath).parent;
        final localFile = File('${appDir.path}\\version.json');
        localFile.writeAsStringSync(payload);

        // Save in AppData
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData\\HotelPro');
          if (!dir.existsSync()) dir.createSync(recursive: true);
          File('$appData\\HotelPro\\version.json').writeAsStringSync(payload);
        }
      } catch (e) {
        debugPrint('[AppUpdateService] Could not persist new version: $e');
      }
    }
  }

  static String? _dismissedVersion;
  static bool _isChecking = false;

  /// Detects the target app based on platform and environment
  static AppTarget detectCurrentTarget() {
    if (!kIsWeb && Platform.isWindows) {
      return AppTarget.windowsErp;
    }
    const appId = String.fromEnvironment('APP_ID', defaultValue: '');
    switch (appId) {
      case 'waiter':
        return AppTarget.waiterPos;
      case 'delivery':
        return AppTarget.deliveryBoy;
      case 'housekeeping':
        return AppTarget.housekeeping;
      case 'manager':
        return AppTarget.managerMis;
      case 'customer':
        return AppTarget.customerDining;
      default:
        return AppTarget.waiterPos;
    }
  }

  /// Compare two semantic version strings (e.g., '1.0.4' > '1.0.0')
  static bool isNewerVersion(String latestStr, String currentStr) {
    try {
      final cleanLatest = latestStr.toLowerCase().replaceAll('v', '').trim();
      final cleanCurrent = currentStr.toLowerCase().replaceAll('v', '').trim();

      final latestParts = cleanLatest.split('+');
      final currentParts = cleanCurrent.split('+');

      final latestSegments = latestParts[0].split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final currentSegments = currentParts[0].split('.').map((s) => int.tryParse(s) ?? 0).toList();

      while (latestSegments.length < 3) {
        latestSegments.add(0);
      }
      while (currentSegments.length < 3) {
        currentSegments.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestSegments[i] > currentSegments[i]) return true;
        if (latestSegments[i] < currentSegments[i]) return false;
      }

      if (latestParts.length > 1 && currentParts.length > 1) {
        final latestBuild = int.tryParse(latestParts[1]) ?? 0;
        final currentBuild = int.tryParse(currentParts[1]) ?? 0;
        return latestBuild > currentBuild;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks GitHub API for the latest release
  static Future<AppUpdateInfo?> checkLatestRelease({AppTarget? targetApp}) async {
    final target = targetApp ?? detectCurrentTarget();
    final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'HotelPro-AppUpdater');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        final tagName = json['tag_name']?.toString() ?? '1.0.0';
        final cleanTag = tagName.replaceAll('v', '').trim();
        final releaseTitle = json['name']?.toString() ?? 'HotelPro Release $tagName';
        final rawBody = json['body']?.toString() ?? '';
        final String releaseNotes;
        if (rawBody.contains('github.com') ||
            rawBody.contains('compare/') ||
            rawBody.contains('Full Changelog') ||
            rawBody.trim().isEmpty) {
          releaseNotes = 'A new version with performance improvements and bug fixes is ready.';
        } else {
          releaseNotes = rawBody.trim();
        }
        final releasePageUrl = json['html_url']?.toString() ?? 'https://github.com/$repoOwner/$repoName/releases/latest';
        final publishedAtStr = json['published_at']?.toString();
        final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

        // Find asset matching the active app
        String downloadUrl = 'https://github.com/$repoOwner/$repoName/releases/latest/download/${target.releaseFileName}';
        final assets = json['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name']?.toString() ?? '';
            if (name.toLowerCase() == target.releaseFileName.toLowerCase()) {
              downloadUrl = asset['browser_download_url']?.toString() ?? downloadUrl;
              break;
            }
          }
        }

        final installedVer = await getInstalledVersionAsync();
        final hasUpdate = isNewerVersion(cleanTag, installedVer);

        return AppUpdateInfo(
          currentVersion: installedVer,
          latestVersion: cleanTag,
          releaseTitle: releaseTitle,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          releasePageUrl: releasePageUrl,
          hasUpdate: hasUpdate,
          targetApp: target,
          publishedAt: publishedAt,
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking GitHub release: $e');
    }

    return null;
  }

  /// Checks for updates and displays the modal if an update is available
  static Future<void> checkAndPrompt(
    BuildContext context, {
    AppTarget? targetApp,
    bool silent = true,
  }) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final info = await checkLatestRelease(targetApp: targetApp);

      if (!context.mounted) return;

      if (info != null && info.hasUpdate) {
        if (silent && _dismissedVersion == info.latestVersion) {
          return;
        }

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AppUpdateDialog(
            updateInfo: info,
            onDismiss: () {
              _dismissedVersion = info.latestVersion;
              Navigator.of(ctx).pop();
            },
          ),
        );
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ HotelPro ${info?.targetApp.displayName ?? 'App'} is up to date! (v$currentInstalledVersion)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1E8449),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error prompting update: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Downloads file with progress following redirects
  static Future<void> downloadFileWithProgress({
    required String url,
    required File saveFile,
    required Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    var currentUrl = Uri.parse(url);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    HttpClientResponse? response;
    int redirectCount = 0;

    while (redirectCount < 6) {
      final request = await client.getUrl(currentUrl);
      request.headers.set('User-Agent', 'HotelPro-AppUpdater');
      request.headers.set('Accept', 'application/octet-stream');
      response = await request.close();

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers.value('location');
        if (location != null) {
          currentUrl = Uri.parse(location);
          redirectCount++;
          continue;
        }
      }
      break;
    }

    if (response == null || response.statusCode != 200) {
      throw Exception('Server returned HTTP ${response?.statusCode} when downloading update package.');
    }

    final totalBytes = response.contentLength;
    int receivedBytes = 0;

    if (saveFile.existsSync()) {
      try {
        saveFile.deleteSync();
      } catch (_) {}
    }

    final sink = saveFile.openWrite();
    await for (final chunk in response) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      final progress = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
      onProgress(progress, receivedBytes, totalBytes);
    }
    await sink.flush();
    await sink.close();
  }

  static const MethodChannel _installerChannel = MethodChannel('com.isecuresystem.hotelpro/installer');

  /// Completely automated In-App Updater for Windows Desktop ERP:
  /// 1. Downloads the new release zip inside the app with progress
  /// 2. Extracts to %TEMP%
  /// 3. Spawns background updater script and restarts app automatically
  static Future<void> performWindowsInAppUpdate(
    AppUpdateInfo info, {
    required Function(double progress, String status) onProgress,
  }) async {
    if (!Platform.isWindows) return;

    final tempDir = Directory.systemTemp;
    final zipFile = File('${tempDir.path}\\hotelpro_update_${info.latestVersion}.zip');
    final extractDir = Directory('${tempDir.path}\\hotelpro_extracted_${info.latestVersion}');

    onProgress(0.05, 'Connecting to update server...');

    // 1. Download
    await downloadFileWithProgress(
      url: info.downloadUrl,
      saveFile: zipFile,
      onProgress: (pct, received, total) {
        final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
        final totalMb = total > 0 ? (total / (1024 * 1024)).toStringAsFixed(1) : '?';
        final pctDisplay = (pct * 100).toInt();
        onProgress(0.05 + (pct * 0.75), 'Downloading update package: $pctDisplay% ($receivedMb MB / $totalMb MB)');
      },
    );

    // 2. Extract
    onProgress(0.85, 'Extracting and verifying update package...');
    if (extractDir.existsSync()) {
      try {
        extractDir.deleteSync(recursive: true);
      } catch (_) {}
    }
    extractDir.createSync(recursive: true);

    // Try tar.exe (fastest native on Win10/11)
    var extractOk = false;
    try {
      final tarRun = await Process.run('tar.exe', ['-xf', zipFile.path, '-C', extractDir.path]);
      if (tarRun.exitCode == 0) {
        extractOk = true;
      }
    } catch (_) {}

    if (!extractOk) {
      // Fallback: PowerShell Expand-Archive
      onProgress(0.90, 'Extracting files via Windows PowerShell...');
      final psRun = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        'Expand-Archive -LiteralPath "${zipFile.path}" -DestinationPath "${extractDir.path}" -Force',
      ]);
      if (psRun.exitCode != 0) {
        throw Exception('Extraction failed: ${psRun.stderr}');
      }
    }

    // 3. Locate source folder
    String effectiveSource = extractDir.path;
    final topEntities = extractDir.listSync();
    final hasExeInRoot = topEntities.any((e) => e.path.toLowerCase().endsWith('.exe'));
    if (!hasExeInRoot) {
      for (final entity in topEntities) {
        if (entity is Directory) {
          final subEntities = entity.listSync();
          if (subEntities.any((e) => e.path.toLowerCase().endsWith('.exe'))) {
            effectiveSource = entity.path;
            break;
          }
        }
      }
    }

    // 4. Target App Directory & Exe Path
    final currentExePath = Platform.resolvedExecutable;
    final currentAppDir = File(currentExePath).parent.path;

    onProgress(0.95, 'Preparing in-place replacement and restart...');

    // Save updated version manifest into effectiveSource (so robocopy carries it), currentAppDir and AppData
    saveInstalledVersion(info.latestVersion);
    try {
      final payload = jsonEncode({
        'version': info.latestVersion.replaceAll('v', '').trim(),
        'updatedAt': DateTime.now().toIso8601String(),
        'product': 'HotelPro Enterprise Windows ERP',
      });
      File('$effectiveSource\\version.json').writeAsStringSync(payload);
    } catch (_) {}

    // Clean paths to avoid the Windows cmd `\"` trailing backslash escaping bug
    final cleanSource = effectiveSource.replaceAll(RegExp(r'[/\\]+$'), '');
    final cleanTarget = currentAppDir.replaceAll(RegExp(r'[/\\]+$'), '');
    final cleanExe = currentExePath.replaceAll(RegExp(r'[/\\]+$'), '');

    // 5. Generate detached batch updater script
    final updaterBat = File('${tempDir.path}\\hotelpro_inplace_updater.bat');
    final scriptContent = '''@echo off
chcp 65001 >nul
title HotelPro ERP Auto-Updater
echo ========================================================
echo   Updating HotelPro ERP to v${info.latestVersion}...
echo   Please wait 2-3 seconds while files are updated.
echo ========================================================
ping 127.0.0.1 -n 3 >nul
taskkill /F /IM hotelpro.exe >nul 2>&1
robocopy "$cleanSource" "$cleanTarget" /E /IS /IT /R:2 /W:1 /NP /NJH /NJS
cd /d "$cleanTarget"
start "" "$cleanExe"
ping 127.0.0.1 -n 3 >nul
del "${zipFile.path}" 2>nul
rmdir /s /q "${extractDir.path}" 2>nul
(goto) 2>nul & del "%~f0"
exit
''';

    await updaterBat.writeAsString(scriptContent);

    onProgress(1.0, '✅ Update ready! Restarting HotelPro in 2 seconds...');
    await Future.delayed(const Duration(milliseconds: 1200));

    // 6. Launch detached batch file and exit current app cleanly
    await Process.start(
      'cmd.exe',
      ['/c', updaterBat.path],
      mode: ProcessStartMode.detached,
    );

    exit(0);
  }

  /// In-App Updater for Android Mobile Apps:
  /// 1. Downloads the APK directly inside the app with real-time percentage and MB progress
  /// 2. Saves to app cache directory
  /// 3. Invokes native Android package installer via MethodChannel
  static Future<void> performAndroidInAppUpdate(
    AppUpdateInfo info, {
    required Function(double progress, String status) onProgress,
  }) async {
    if (!Platform.isAndroid) return;

    // 1. Resolve standard Android cache directory to prevent FileProvider code_cache errors
    String downloadDirPath = Directory.systemTemp.path;
    try {
      final nativeCache = await _installerChannel.invokeMethod<String>('getCacheDir');
      if (nativeCache != null && nativeCache.isNotEmpty) {
        downloadDirPath = nativeCache;
      }
    } catch (_) {}

    final targetDir = Directory(downloadDirPath);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final apkFile = File('${targetDir.path}/hotelpro_update_${info.latestVersion}.apk');

    // Clean up any stale or previous update APKs from the cache folder
    try {
      if (targetDir.existsSync()) {
        for (final entity in targetDir.listSync()) {
          if (entity is File &&
              entity.path.contains('hotelpro_update_') &&
              entity.path.endsWith('.apk') &&
              entity.path != apkFile.path) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    onProgress(0.05, 'Connecting to update server...');

    // 2. Download APK with stream progress
    await downloadFileWithProgress(
      url: info.downloadUrl,
      saveFile: apkFile,
      onProgress: (pct, received, total) {
        final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
        final totalMb = total > 0 ? (total / (1024 * 1024)).toStringAsFixed(1) : '?';
        final pctDisplay = (pct * 100).toInt();
        onProgress(0.05 + (pct * 0.90), 'Downloading APK: $pctDisplay% ($receivedMb MB / $totalMb MB)');
      },
    );

    // Verify downloaded APK exists and is non-empty
    if (!apkFile.existsSync() || apkFile.lengthSync() == 0) {
      throw Exception('Downloaded update package is missing or corrupted. Please try again.');
    }

    onProgress(0.98, 'Verifying APK & launching package installer...');

    // 3. Invoke native package installer via MethodChannel
    try {
      final success = await _installerChannel.invokeMethod<bool>('installApk', {
        'filePath': apkFile.path,
      });

      if (success != true) {
        throw Exception('Could not launch Android package installer.');
      }

      onProgress(1.0, 'Installer launched! Please confirm the update on your screen.');
    } on PlatformException catch (pe) {
      throw Exception('Installation error: ${pe.message ?? pe.code}');
    }
  }

  /// Direct method to launch the update download link in external browser
  static Future<void> downloadUpdate(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Could not launch download URL: $e');
    }
  }
}
