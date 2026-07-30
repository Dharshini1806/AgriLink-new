import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary       = Color(0xFF2E8B57); // SeaGreen
  static const Color primaryLight  = Color(0xFF4CAF72);
  static const Color primaryDark   = Color(0xFF1B5E3A);
  static const Color secondary     = Color(0xFFFF8F00); // Amber for CTAs
  static const Color accent        = Color(0xFF00BCD4);

  // Neutrals
  static const Color background    = Color(0xFFF7F9F4);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceVariant= Color(0xFFEFF3EB);
  static const Color border        = Color(0xFFDDE3D5);

  // Text
  static const Color textPrimary   = Color(0xFF1A1F16);
  static const Color textSecondary = Color(0xFF5A6354);
  static const Color textHint      = Color(0xFF9BA89A);

  // Status
  static const Color success       = Color(0xFF4CAF50);
  static const Color warning       = Color(0xFFFF9800);
  static const Color error         = Color(0xFFE53935);
  static const Color info          = Color(0xFF1976D2);

  // Quality Grades
  static const Color gradeA        = Color(0xFF2E7D32); // Premium
  static const Color gradeB        = Color(0xFFF57F17); // Standard
  static const Color gradeC        = Color(0xFF6D4C41); // Economy

  // Order Status
  static const Color statusPending  = Color(0xFFFF9800);
  static const Color statusConfirmed= Color(0xFF2196F3);
  static const Color statusPacked   = Color(0xFF9C27B0);
  static const Color statusDelivery = Color(0xFF00BCD4);
  static const Color statusDelivered= Color(0xFF4CAF50);
  static const Color statusCancelled= Color(0xFFE53935);

  // Chat
  static const Color sentBubble     = Color(0xFF2E8B57);
  static const Color receivedBubble = Color(0xFFEFF3EB);

  // Dark mode surfaces
  static const Color darkSurface    = Color(0xFF1E2822);
  static const Color darkBackground = Color(0xFF141A18);
}
