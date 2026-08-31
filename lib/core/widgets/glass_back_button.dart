import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/main_navigation_screen.dart';

class GlassBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color iconColor;
  final double size;

  const GlassBackButton({
    super.key,
    this.onPressed,
    this.iconColor = AppColors.textPrimary,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: UnconstrainedBox(
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.65),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed ??
                      () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                  child: Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
