import 'package:flutter/material.dart';

/// OLOF Eye-Friendly Color System
/// Specifically calibrated for ophthalmology & ENT clinic patients:
/// - Anti-glare soft background (reduces photophobia, haloing & eye strain)
/// - Ultra-high contrast WCAG AAA typography (for patients with low vision, cataracts, post-dilation)
/// - Color-blind safe accents & clear visual hierarchy
class AppColors {
  AppColors._();

  // ── BRAND ──────────────────────────────────────────────
  static const Color brandNavy = Color(0xFF0F1E36);
  static const Color brandBlue = Color(0xFF1D5D9B);
  static const Color brandCyan = Color(0xFF0EA5E9);
  static const Color brandLightBlue = Color(0xFF38BDF8);

  // ── EYE-COMFORT LIGHT PALETTE (Day / Anti-Glare Soft White) ──
  static const Color lightBg = Color(0xFFF1F5F9);         // Soft slate-pearl background (absorbs glare)
  static const Color lightSurface = Color(0xFFFFFFFF);    // Crisp white card surface
  static const Color lightSurfaceMid = Color(0xFFF8FAFC); // Subtle card section
  static const Color lightSurfaceHover = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);      // High-contrast clean card border
  static const Color lightBorderSoft = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Deep slate obsidian (WCAG AAA > 13:1)
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextDisabled = Color(0xFF64748B);

  // ── EYE-COMFORT DARK PALETTE (Night / Low-Light Slate) ──
  static const Color surfaceDarkest = Color(0xFF0B131E);
  static const Color surfaceDark = Color(0xFF132030);
  static const Color surfaceMid = Color(0xFF1B2B3E);
  static const Color surfaceLight = Color(0xFF263C54);
  static const Color surfaceHover = Color(0xFF344F6D);
  static const Color surfaceOverlay = Color(0x331B2838);

  // ── PRIMARY ACCENT (Calming Medical Blues) ─────────────
  static const Color primary = Color(0xFF0284C7);          // Ocean / Medical blue
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primarySoft = Color(0xFFBAE6FD);
  static const Color primaryDark = Color(0xFF0369A1);

  // ── SECONDARY ACCENT (Calming Teal / Cyan) ─────────────
  static const Color cyanCalm = Color(0xFF0D9488);
  static const Color cyanLight = Color(0xFF2DD4BF);

  // ── STATUS (Color-blind safe & High Visibility) ────────
  static const Color success = Color(0xFF059669);          // Emerald
  static const Color warning = Color(0xFFD97706);          // Warm amber
  static const Color urgent = Color(0xFFDC2626);           // Coral red
  static const Color error = urgent;                      // Semantic alias for danger/delete
  static const Color info = Color(0xFF4F46E5);             // Indigo
  static const Color nowServing = Color(0xFFF59E0B);       // Golden amber (high eye contrast)
  static const Color nowServingTextDark = Color(0xFF78350F);
  static const Color onHold = Color(0xFF8B5CF6);           // Soft violet

  // ── TEXT ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);      // Warm off-white for dark mode
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);          // For light bg

  // ── DEPARTMENT COLORS ──────────────────────────────────
  static const Color entColor = Color(0xFF0284C7);          // Deep Cyan-Blue for ENT
  static const Color entColorDark = Color(0xFF0369A1);
  static const Color eyesColor = Color(0xFF2563EB);         // Royal Indigo for Eyes / Ophthalmology
  static const Color eyesColorDark = Color(0xFF1D4ED8);
  static const Color entPrimary = entColor;
  static const Color eyesPrimary = eyesColor;

  // ── DOCTOR PALETTE (Medical Emerald - replaces harsh blue) ──
  static const Color doctorPrimary = Color(0xFF059669);
  static const Color doctorDark = Color(0xFF047857);
  static const Color doctorDeep = Color(0xFF064E3B);
  static const Color doctorLight = Color(0xFF10B981);
  static const Color doctorSurfaceLight = Color(0xFFF0FDF4);
  static const Color doctorSurfaceDark = Color(0xFF022C22);

  // ── GRADIENTS ──────────────────────────────────────────
  static const LinearGradient doctorGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF064E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surfaceDark, surfaceDarkest],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightSurfaceGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFEDF2F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient entGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0E7490)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient eyesGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── SHADOWS ────────────────────────────────────────────
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
