import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/hotel_repository.dart';

/// Universal Hotel Logo Component that automatically displays the custom hotel
/// logo configured in Developer Business Setup Studio, or falls back to the
/// default HotelPro brand asset.
class HotelLogoWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final HotelRepository? repo;
  final Widget? fallback;
  final Color? backgroundColor;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;

  const HotelLogoWidget({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.repo,
    this.fallback,
    this.backgroundColor,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    HotelRepository? effectiveRepo = repo;
    if (effectiveRepo == null) {
      try {
        effectiveRepo = Provider.of<HotelRepository>(context, listen: true);
      } catch (_) {
        effectiveRepo = null;
      }
    }

    final bytes = effectiveRepo?.clientLogoBytes;
    final path = effectiveRepo?.clientLogoPath;

    Widget imageWidget;
    if (bytes != null && bytes.isNotEmpty) {
      imageWidget = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else if (path != null && path.isNotEmpty && File(path).existsSync()) {
      imageWidget = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      imageWidget = _buildFallback();
    }

    Widget content = imageWidget;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (backgroundColor != null || border != null || borderRadius != null) {
      content = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: content,
        ),
      );
    } else if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildFallback() {
    if (fallback != null) return fallback!;
    return Image.asset(
      'lib/ui/features/master/assets/hotel_logo.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
