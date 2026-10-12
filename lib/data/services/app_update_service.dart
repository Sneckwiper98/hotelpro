import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_constants.dart';
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
  static const String currentInstalledVersion = '1.0.0';

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

  /// Compare two semantic version strings (e.g., '1.0.3' > '1.0.0')
  static bool isNewerVersion(String latestStr, String currentStr) {
    try {
      final cleanLatest = latestStr.toLowerCase().replaceAll('v', '').trim();
      final cleanCurrent = currentStr.toLowerCase().replaceAll('v', '').trim();

      final latestParts = cleanLatest.split('+');
      final currentParts = cleanCurrent.split('+');

      final latestSegments = latestParts[0].split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final currentSegments = currentParts[0].split('.').map((s) => int.tryParse(s) ?? 0).toList();

      while (latestSegments.length < 3) latestSegments.add(0);
      while (currentSegments.length < 3) currentSegments.add(0);

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
        final releaseNotes = json['body']?.toString() ?? 'A new version with performance improvements and bug fixes is ready.';
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

        final hasUpdate = isNewerVersion(cleanTag, currentInstalledVersion);

        return AppUpdateInfo(
          currentVersion: currentInstalledVersion,
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

    // Fallback: If GitHub API is temporarily rate-limited or unavailable, construct default info
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
        // Skip if user already dismissed this exact version in current session (unless manual check)
        if (silent && _dismissedVersion == info.latestVersion) {
          return;
        }

        await showDialog(
          context: context,
          barrierDismissible: true,
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

  /// Direct method to launch the update download
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
