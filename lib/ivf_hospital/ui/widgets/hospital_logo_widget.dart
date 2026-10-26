import 'package:flutter/material.dart';

/// Renders the Hospital Brand Logo configured in settings
/// Used across all Bills, Reports, Print Previews, and Headers
class HospitalLogoWidget extends StatelessWidget {
  final String logoPathOrUrl;
  final double size;
  final Color? fallbackColor;

  const HospitalLogoWidget({
    super.key,
    required this.logoPathOrUrl,
    this.size = 36,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    if (logoPathOrUrl.startsWith('http://') || logoPathOrUrl.startsWith('https://')) {
      return Image.network(
        logoPathOrUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => _buildPresetEmblem('fertility_lotus'),
      );
    }

    if (logoPathOrUrl.startsWith('preset:')) {
      final presetKey = logoPathOrUrl.replaceFirst('preset:', '');
      return _buildPresetEmblem(presetKey);
    }

    // Default built-in Medical Embryo / Fertility Emblem
    return _buildPresetEmblem('fertility_lotus');
  }

  Widget _buildPresetEmblem(String presetKey) {
    IconData iconData;
    Color emblemBg;
    Color iconColor;

    switch (presetKey) {
      case 'caduceus':
        iconData = Icons.health_and_safety_rounded;
        emblemBg = const Color(0xFF0B3C5D);
        iconColor = const Color(0xFFF1C40F);
        break;
      case 'heart_cross':
        iconData = Icons.add_moderator_rounded;
        emblemBg = const Color(0xFF1E8449);
        iconColor = Colors.white;
        break;
      case 'dna_embryo':
        iconData = Icons.biotech_rounded;
        emblemBg = const Color(0xFF6C3483);
        iconColor = const Color(0xFF85C1E9);
        break;
      case 'fertility_lotus':
      default:
        iconData = Icons.local_hospital_rounded;
        emblemBg = const Color(0xFF0B3C5D);
        iconColor = Colors.white;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: emblemBg,
        borderRadius: BorderRadius.circular(size * 0.15),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.58,
          color: fallbackColor ?? iconColor,
        ),
      ),
    );
  }
}
