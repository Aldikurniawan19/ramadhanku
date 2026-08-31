import 'package:flutter/material.dart';

enum SnackBarType { success, error, info }

class ModernSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    SnackBarType type = SnackBarType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color bgColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case SnackBarType.success:
        bgColor = const Color(0xFF0F766E); // Deep Teal
        iconColor = const Color(0xFF34D399); // Emerald Light
        iconData = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        bgColor = const Color(0xFF881337); // Deep Red
        iconColor = const Color(0xFFFDA4AF); // Rose Light
        iconData = Icons.error_rounded;
        break;
      case SnackBarType.info:
        bgColor = const Color(0xFF0F172A); // Slate Dark
        iconColor = const Color(0xFF38BDF8); // Sky Light
        iconData = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: iconColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: title != null ? 11.5 : 13,
                        fontWeight: title != null ? FontWeight.w400 : FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
