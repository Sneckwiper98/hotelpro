import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/services/hotel_sync_bridge_service.dart';
import '../../../../data/services/app_update_service.dart';

class MobileAppReleaseInfo {
  final String id;
  final String title;
  final String installedAppName;
  final String packageId;
  final String fileName;
  final String entryPoint;
  final String batchTarget;
  final IconData icon;
  final Color themeColor;
  final String description;
  final String tag;

  const MobileAppReleaseInfo({
    required this.id,
    required this.title,
    required this.installedAppName,
    required this.packageId,
    required this.fileName,
    required this.entryPoint,
    required this.batchTarget,
    required this.icon,
    required this.themeColor,
    required this.description,
    required this.tag,
  });
}

/// Android Apps Release & Download Center Modal Dialog for Windows ERP
class AndroidAppsReleaseDialog extends StatefulWidget {
  const AndroidAppsReleaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AndroidAppsReleaseDialog(),
    );
  }

  @override
  State<AndroidAppsReleaseDialog> createState() => _AndroidAppsReleaseDialogState();
}

class _AndroidAppsReleaseDialogState extends State<AndroidAppsReleaseDialog> {
  final List<MobileAppReleaseInfo> _apps = const [
    MobileAppReleaseInfo(
      id: 'waiter',
      title: 'Staff Waiter & Captain POS App',
      installedAppName: 'HotelPro Waiter POS',
      packageId: 'com.isecuresystem.hotelpro.waiter',
      fileName: 'HotelPro_WaiterPOS_v1.0.apk',
      entryPoint: 'lib/main_waiter.dart',
      batchTarget: 'waiter',
      icon: Icons.restaurant_rounded,
      themeColor: Color(0xFF1E8449),
      description: 'Table-side digital ordering, kitchen KOT punching, customer registration & WhatsApp bill sharing.',
      tag: 'F&B Operations',
    ),
    MobileAppReleaseInfo(
      id: 'delivery',
      title: 'Delivery Partner / Rider App',
      installedAppName: 'HotelPro Delivery Boy',
      packageId: 'com.isecuresystem.hotelpro.delivery',
      fileName: 'HotelPro_DeliveryBoy_v1.0.apk',
      entryPoint: 'lib/main_delivery.dart',
      batchTarget: 'delivery',
      icon: Icons.two_wheeler_rounded,
      themeColor: Color(0xFFD35400),
      description: 'Rider dispatch, real-time GPS navigation, order pickup, cash collection & live delivery updates.',
      tag: 'Delivery Logistics',
    ),
    MobileAppReleaseInfo(
      id: 'housekeeping',
      title: 'Housekeeping & Room Inspection App',
      installedAppName: 'HotelPro Housekeeping',
      packageId: 'com.isecuresystem.hotelpro.housekeeping',
      fileName: 'HotelPro_Housekeeping_v1.0.apk',
      entryPoint: 'lib/main_housekeeping.dart',
      batchTarget: 'housekeeping',
      icon: Icons.cleaning_services_rounded,
      themeColor: Color(0xFF6C3483),
      description: 'Room cleaning checklist, supervisor inspection approval, and dirty/clean status sync to Front Desk.',
      tag: 'Room Management',
    ),
    MobileAppReleaseInfo(
      id: 'manager',
      title: 'Hotel Manager & Owner Live MIS App',
      installedAppName: 'HotelPro Manager MIS',
      packageId: 'com.isecuresystem.hotelpro.manager',
      fileName: 'HotelPro_ManagerMIS_v1.0.apk',
      entryPoint: 'lib/main_manager.dart',
      batchTarget: 'manager',
      icon: Icons.analytics_rounded,
      themeColor: Color(0xFF922B21),
      description: 'Live executive revenue, room occupancy %, daily collection breakdown, and financial pulse.',
      tag: 'Executive MIS',
    ),
    MobileAppReleaseInfo(
      id: 'customer',
      title: 'Customer Food & Dining App',
      installedAppName: 'HotelPro Customer Dining',
      packageId: 'com.isecuresystem.hotelpro.customer',
      fileName: 'HotelPro_CustomerDining_v1.0.apk',
      entryPoint: 'lib/main_customer.dart',
      batchTarget: 'customer',
      icon: Icons.fastfood_rounded,
      themeColor: Color(0xFFE23744),
      description: 'Digital QR table menu, room service, online delivery within 10km & Razorpay payment integration.',
      tag: 'Guest Dining',
    ),
  ];

  bool _isExporting = false;
  String? _statusBanner;
  Color _statusBannerColor = const Color(0xFF27AE60);

  File? _findApkFile(String fileName) {
    final altName = fileName.replaceAll('_v1.0', '');

    // 1. Check in releases/ directory
    final releasesDir = Directory('releases');
    if (releasesDir.existsSync()) {
      final f = File('${releasesDir.path}${Platform.pathSeparator}$fileName');
      if (f.existsSync()) return f;
      final altF = File('${releasesDir.path}${Platform.pathSeparator}$altName');
      if (altF.existsSync()) return altF;
    }

    // 2. Check in build/app/outputs/flutter-apk/
    final buildDir = Directory('build/app/outputs/flutter-apk');
    if (buildDir.existsSync()) {
      final namedFile = File('${buildDir.path}${Platform.pathSeparator}$fileName');
      if (namedFile.existsSync()) return namedFile;
      final altNamedFile = File('${buildDir.path}${Platform.pathSeparator}$altName');
      if (altNamedFile.existsSync()) return altNamedFile;

      // Fallback: app-release.apk
      final defaultRelease = File('${buildDir.path}${Platform.pathSeparator}app-release.apk');
      if (defaultRelease.existsSync()) return defaultRelease;
    }

    return null;
  }

  void _openReleasesFolder() {
    try {
      final currentDir = Directory.current.path;
      final releasesPath = '$currentDir${Platform.pathSeparator}releases';
      final dir = Directory(releasesPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      Process.run('explorer.exe', [releasesPath]);
    } catch (e) {
      debugPrint('Failed to open explorer: $e');
    }
  }

  Future<void> _saveApkAs(MobileAppReleaseInfo app, File sourceFile) async {
    try {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${app.title} APK — Select Destination',
        fileName: app.fileName,
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (outputPath == null) return; // User cancelled

      setState(() {
        _isExporting = true;
        _statusBanner = 'Saving ${app.fileName} to chosen folder...';
        _statusBannerColor = const Color(0xFF2980B9);
      });

      final finalPath = outputPath.toLowerCase().endsWith('.apk') ? outputPath : '$outputPath.apk';
      await sourceFile.copy(finalPath);

      setState(() {
        _isExporting = false;
        _statusBanner = '✅ Successfully saved ${app.fileName} to:\n$finalPath';
        _statusBannerColor = const Color(0xFF27AE60);
      });

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      final snackBarController = messenger.showSnackBar(
        SnackBar(
          content: Text('🎉 APK saved successfully to $finalPath'),
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(seconds: 30),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          action: SnackBarAction(
            label: 'Open Folder',
            textColor: Colors.white,
            onPressed: () {
              final folder = File(finalPath).parent.path;
              Process.run('explorer.exe', [folder]);
            },
          ),
        ),
      );
      Timer(const Duration(seconds: 30), () {
        try {
          snackBarController.close();
        } catch (_) {}
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusBanner = '❌ Failed to save APK: $e';
        _statusBannerColor = const Color(0xFFC0392B);
      });
    }
  }

  Future<void> _saveAllApksToFolder() async {
    try {
      final String? targetDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Destination Folder for All Android APKs',
      );

      if (targetDir == null) return; // Cancelled

      setState(() {
        _isExporting = true;
        _statusBanner = 'Exporting all available APKs to $targetDir...';
        _statusBannerColor = const Color(0xFF2980B9);
      });

      int savedCount = 0;
      for (final app in _apps) {
        final source = _findApkFile(app.fileName);
        if (source != null) {
          final dest = '$targetDir${Platform.pathSeparator}${app.fileName}';
          await source.copy(dest);
          savedCount++;
        }
      }

      setState(() {
        _isExporting = false;
        _statusBanner = savedCount > 0
            ? '✅ Successfully exported $savedCount APK(s) to:\n$targetDir'
            : '⚠️ No compiled APKs found to export. Please build them first using build_release.bat';
        _statusBannerColor = savedCount > 0 ? const Color(0xFF27AE60) : const Color(0xFFD35400);
      });

      if (savedCount > 0 && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        final snackBarController = messenger.showSnackBar(
          SnackBar(
            content: Text('🎉 $savedCount APK(s) exported to $targetDir'),
            backgroundColor: const Color(0xFF27AE60),
            duration: const Duration(seconds: 30),
            showCloseIcon: true,
            closeIconColor: Colors.white,
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () => Process.run('explorer.exe', [targetDir]),
            ),
          ),
        );
        Timer(const Duration(seconds: 30), () {
          try {
            snackBarController.close();
          } catch (_) {}
        });
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusBanner = '❌ Export error: $e';
        _statusBannerColor = const Color(0xFFC0392B);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverIp = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
    final serverPort = HotelSyncBridgeService.instance.serverPort;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 820,
        height: 680,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF0C2461),
              child: Row(
                children: [
                  const Icon(Icons.install_mobile_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Android Mobile Apps Release & Download Center',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Export, download and save standalone APKs to any folder, USB drive, or download wirelessly over hotel Wi-Fi.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Top Action Ribbon ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: ClassicErpTheme.borderLight)),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _saveAllApksToFolder,
                    icon: const Icon(Icons.drive_folder_upload_rounded, size: 15),
                    label: const Text('Save All APKs to Custom Folder...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openReleasesFolder,
                    icon: const Icon(Icons.folder_open_rounded, size: 15),
                    label: const Text('Open Releases Folder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B4F72),
                      side: const BorderSide(color: Color(0xFF1B4F72)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      AppUpdateService.checkAndPrompt(context, silent: false);
                    },
                    icon: const Icon(Icons.cloud_sync_rounded, size: 15, color: Color(0xFF0C2461)),
                    label: const Text('Check for Updates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0C2461)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Refresh Status', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClassicErpTheme.textMain,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const Spacer(),
                  // LAN Sync IP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2F8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFAED6F1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_tethering_rounded, size: 13, color: Color(0xFF1B4F72)),
                        const SizedBox(width: 4),
                        Text(
                          'LAN Host: $serverIp:$serverPort',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Status Banner (if any) ──────────────────────────────────────
            if (_statusBanner != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: _statusBannerColor.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: _statusBannerColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusBanner!,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusBannerColor),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _statusBanner = null),
                      child: Icon(Icons.close, size: 14, color: _statusBannerColor),
                    ),
                  ],
                ),
              ),

            // ── List of All 5 Standalone Mobile Apps ────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _apps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final app = _apps[idx];
                  final apkFile = _findApkFile(app.fileName);
                  final isReady = apkFile != null;

                  String fileSizeText = 'Unknown';
                  String modifiedDateText = '';
                  if (isReady) {
                    final bytes = apkFile.lengthSync();
                    fileSizeText = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                    modifiedDateText = DateFormat('dd MMM yyyy, hh:mm a').format(apkFile.lastModifiedSync());
                  }

                  final wirelessUrl = 'http://$serverIp:$serverPort/releases/${app.fileName}';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isReady ? app.themeColor.withValues(alpha: 0.5) : const Color(0xFFBDC3C7),
                        width: isReady ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: app.themeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: app.themeColor.withValues(alpha: 0.3)),
                              ),
                              child: Icon(app.icon, color: app.themeColor, size: 24),
                            ),
                            const SizedBox(width: 12),

                            // App Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        app.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ClassicErpTheme.textMain),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: app.themeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          app.tag,
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: app.themeColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    app.description,
                                    style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEBF5FB),
                                          borderRadius: BorderRadius.circular(3),
                                          border: Border.all(color: const Color(0xFFAED6F1)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.install_mobile_rounded, size: 11, color: Color(0xFF1B4F72)),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Install Name: ${app.installedAppName}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F4F4),
                                          borderRadius: BorderRadius.circular(3),
                                          border: Border.all(color: const Color(0xFFD5D8DC)),
                                        ),
                                        child: Text(
                                          'ID: ${app.packageId}',
                                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF2C3E50), fontFamily: 'monospace'),
                                        ),
                                      ),
                                      Text('File: ${app.fileName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Status Badge & Download Action
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isReady ? const Color(0xFFD4EFDF) : const Color(0xFFFCF3CF),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: isReady ? const Color(0xFF27AE60) : const Color(0xFFF39C12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isReady ? Icons.check_circle_rounded : Icons.pending_rounded,
                                        size: 13,
                                        color: isReady ? const Color(0xFF1E8449) : const Color(0xFFB7950B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isReady ? 'Ready ($fileSizeText)' : 'Build Pending',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isReady ? const Color(0xFF1E8449) : const Color(0xFFB7950B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (modifiedDateText.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Built: $modifiedDateText',
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  ),
                                ],
                                const SizedBox(height: 8),

                                // Main Download Button
                                ElevatedButton.icon(
                                  onPressed: isReady ? () => _saveApkAs(app, apkFile) : null,
                                  icon: const Icon(Icons.download_rounded, size: 14),
                                  label: const Text('Save APK As...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: app.themeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    disabledBackgroundColor: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 6),

                        // Wireless Mobile Download Link & Terminal Instructions
                        Row(
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 13, color: Color(0xFF1B4F72)),
                            const SizedBox(width: 4),
                            const Text('Wi-Fi Phone Download URL: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                            SelectableText(
                              wirelessUrl,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF2980B9), decoration: TextDecoration.underline),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: wirelessUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('📋 Copied phone download link: $wirelessUrl'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_rounded, size: 11, color: Colors.black87),
                                    SizedBox(width: 3),
                                    Text('Copy Link', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Build command copy
                            InkWell(
                              onTap: () {
                                final cmd = 'flutter build apk -t ${app.entryPoint} -PtargetApp=${app.batchTarget} --release';
                                Clipboard.setData(ClipboardData(text: cmd));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('📋 Copied terminal command: $cmd'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Text(
                                'Terminal: .\\build_release.bat ${app.batchTarget}',
                                style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Dialog Footer ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFEAEDED),
                border: Border(top: BorderSide(color: ClassicErpTheme.borderDark)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 15, color: Color(0xFFD35400)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Tip: Click "Save APK As..." to choose any folder on your computer (Downloads, Desktop, Pendrive, etc.).',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF7F8C8D)),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
