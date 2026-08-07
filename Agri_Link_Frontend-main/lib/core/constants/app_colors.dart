import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF6B4226); // Chestnut Brown
  static const Color primaryLight  = Color(0xFF9C6B4A); // Warm Tan
  static const Color primaryDark   = Color(0xFF3E2412); // Dark Espresso
  static const Color secondary     = Color(0xFFD4A017); // Golden Amber
  static const Color accent        = Color(0xFF7B9E3E); // Olive Green

  // ── Gradient Stops ────────────────────────────────────────────────────────
  static const Color gradientStart = Color(0xFFD4A017); // Amber gold
  static const Color gradientMid   = Color(0xFF9C6B4A); // Warm tan
  static const Color gradientEnd   = Color(0xFF6B4226); // Chestnut

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFFFBF7F0); // Warm Cream
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceVariant= Color(0xFFF5EFE6); // Soft Parchment
  static const Color border        = Color(0xFFE8DAC8); // Warm border
  static const Color overlay       = Color(0x1A6B4226); // Brown overlay

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF2C1A0E); // Espresso
  static const Color textSecondary = Color(0xFF7A5C44); // Mocha
  static const Color textHint      = Color(0xFFB8956E); // Warm hint

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF5A7A2E); // Olive success
  static const Color warning       = Color(0xFFD4A017); // Amber warning
  static const Color error         = Color(0xFFB83232); // Terracotta error
  static const Color info          = Color(0xFF2E6B9E); // Dusty blue

  // ── Quality Grades ────────────────────────────────────────────────────────
  static const Color gradeA        = Color(0xFF4A7C3F); // Forest green
  static const Color gradeB        = Color(0xFFD4A017); // Golden amber
  static const Color gradeC        = Color(0xFFB05A35); // Terracotta

  // ── Order Status ──────────────────────────────────────────────────────────
  static const Color statusPending  = Color(0xFFD4A017); // Amber
  static const Color statusConfirmed= Color(0xFF2E6B9E); // Dusty blue
  static const Color statusPacked   = Color(0xFF7B5EA7); // Soft purple
  static const Color statusDelivery = Color(0xFF3E8C6B); // Teal green
  static const Color statusDelivered= Color(0xFF4A7C3F); // Forest green
  static const Color statusCancelled= Color(0xFFB83232); // Terracotta red

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const Color sentBubble     = Color(0xFF6B4226); // Brown
  static const Color receivedBubble = Color(0xFFF5EFE6); // Parchment

  // ── Dark Mode ─────────────────────────────────────────────────────────────
  static const Color darkSurface    = Color(0xFF2A1E14); // Dark espresso surface
  static const Color darkBackground = Color(0xFF1A1108); // Near-black warm
  static const Color darkBorder     = Color(0xFF4A3020); // Dark warm border
}
