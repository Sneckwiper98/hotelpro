import 'package:flutter/material.dart';
import '../../../../config/classic_erp_theme.dart';

/// Standard Win32 / Desktop ERP Text Input Field
/// Features clean 28px height, 1px slate border (#B0BEC5), deep navy focus outline (#1B4F72),
/// proper unclipped padding, and crisp typography.
class ClassicErpInput extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? prefixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool isNumeric;
  final bool obscureText;
  final bool readOnly;
  final double height;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int maxLines;
  final TextStyle? textStyle;

  const ClassicErpInput({
    super.key,
    this.label,
    this.isRequired = false,
    this.controller,
    this.initialValue,
    this.hintText,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.isNumeric = false,
    this.obscureText = false,
    this.readOnly = false,
    this.height = 28.0,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final inputWidget = SizedBox(
      height: maxLines == 1 ? height : (height + (maxLines - 1) * 18.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        onChanged: onChanged,
        cursorColor: const Color(0xFF1B4F72),
        cursorWidth: 1.5,
        cursorHeight: 14,
        style: textStyle ??
            const TextStyle(
              fontSize: 11,
              color: ClassicErpTheme.textMain,
              fontWeight: FontWeight.normal,
            ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: readOnly ? const Color(0xFFF2F4F4) : Colors.white,
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF95A5A6)),
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: ClassicErpTheme.textMain,
          ),
          prefixIcon: prefixIcon,
          prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFFB0BEC5), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFFB0BEC5), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFF1B4F72), width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFFCFD8DC), width: 1.0),
          ),
        ),
      ),
    );

    if (label == null || label!.isEmpty) {
      return inputWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC0392B),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        inputWidget,
      ],
    );
  }
}

/// Standard Win32 / Desktop ERP Dropdown Field
/// Perfectly matches [ClassicErpInput] in height (28px), borders, and padding.
class ClassicErpDropdown<T> extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double height;
  final bool isExpanded;
  final String? hintText;
  final Color? fillColor;

  const ClassicErpDropdown({
    super.key,
    this.label,
    this.isRequired = false,
    required this.value,
    required this.items,
    this.onChanged,
    this.height = 28.0,
    this.isExpanded = true,
    this.hintText,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownWidget = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFB0BEC5), width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: isExpanded,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF566573)),
          hint: hintText != null
              ? Text(
                  hintText!,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF95A5A6)),
                )
              : null,
          style: const TextStyle(
            fontSize: 11,
            color: ClassicErpTheme.textMain,
            fontWeight: FontWeight.normal,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );

    if (label == null || label!.isEmpty) {
      return dropdownWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC0392B),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        dropdownWidget,
      ],
    );
  }
}

/// Compact Search Input Box for Toolbars & Ribbons
class ClassicErpSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double width;
  final double height;

  const ClassicErpSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.width = 220,
    this.height = 26,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF95A5A6)),
          prefixIcon: const Icon(Icons.search, size: 14, color: ClassicErpTheme.textMuted),
          prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? InkWell(
                  onTap: () {
                    controller!.clear();
                    onChanged?.call('');
                    onClear?.call();
                  },
                  child: const Icon(Icons.clear, size: 12, color: ClassicErpTheme.textMuted),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFFB0BEC5), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFFB0BEC5), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFF1B4F72), width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Standardized Form Section Header Ribbon
class ClassicErpSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  const ClassicErpSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color = const Color(0xFF1B4F72),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
