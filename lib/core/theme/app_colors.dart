import 'package:flutter/material.dart';

/// Centralized Color Tokens & Style Utilities for Ramadan App
/// Theme Palette: Premium White, Emerald Green & Soft Islamic Gold
abstract class AppColors {
  // Primary Greens & Design Palette
  static const Color primary = Color(0xFF1E6B65);       // Deep Emerald Teal
  static const Color primaryMedium = Color(0xFF2C8982); // Medium Teal Green
  static const Color primaryLight = Color(0xFFEBF5F4);  // Soft Tint Green Background
  static const Color primaryHover = Color(0xFF144D48);  // Rich Dark Emerald
  static const Color accentGold = Color(0xFFD4AF37);     // Islamic Gold Accent
  static const Color headerBackground = Color(0xFF0D3230); // Deep Teal Header
  static const Color activePrayerBg = Color(0xFF27827B); // Highlighted Prayer Card Fill

  // Background & Surfaces (Soft Warm Cream Palette matching Quran screen)
  static const Color background = Color(0xFFFAF9F6);    // Soft Natural Cream Off-White
  static const Color surface = Color(0xFFFFFFFF);       // Pure White Surface
  static const Color surfaceVariant = Color(0xFFEFF4F3); // Soft Light Tint
  static const Color cardBorder = Color(0xFFE5EDED);    // Delicate Subtle Border

  // Typography & Text Colors
  static const Color textPrimary = Color(0xFF1B2B2A);   // Dark Slate Teal
  static const Color textSecondary = Color(0xFF5A706E); // Muted Teal Grey
  static const Color textMuted = Color(0xFF8B9E9C);     // Soft Muted Text
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Pure White on Dark Surfaces


  // Status Colors
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFFD7E14);
  static const Color danger = Color(0xFFDC3545);
  static const Color info = Color(0xFF0D6EFD);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F5132), Color(0xFF1D976C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B4128), Color(0xFF146C43), Color(0xFF198754)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FBF9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Soft Layered Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0C0F5132),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x200F5132),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];
}
