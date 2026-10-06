import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Modern Indigo & Royal Blue
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryDark = Color(0xFF0F172A); // Slate Dark

  // Accent & Secondary
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color accent = Color(0xFFF59E0B); // Amber / Gold

  // Status Colors
  static const Color statusPaid = Color(0xFF10B981); // Emerald Green
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusOverdue = Color(0xFFEF4444); // Crimson Red
  static const Color statusDraft = Color(0xFF6B7280); // Cool Gray

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC); // Soft Slate Gray
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  // Surface gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
