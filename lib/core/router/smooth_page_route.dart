import 'package:flutter/material.dart';

/// Ultra-smooth WhatsApp-style horizontal slide page route transition.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
                reverseCurve: Curves.easeInCubic,
              ),
            );

            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
        );

  /// Helper static method to push a screen with WhatsApp-style smooth slide
  static Future<T?> navigate<T>(
    BuildContext context,
    Widget targetPage,
  ) {
    return Navigator.push<T>(
      context,
      SmoothPageRoute<T>(
        page: targetPage,
      ),
    );
  }
}
