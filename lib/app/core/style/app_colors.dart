import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Surfaces (dark grey hierarchy) ───────────────────────────────────────
  static const Color background = Color(0xFF141414); // scaffold, deepest
  static const Color surface = Color(0xFF1E1E1E); // cards, sheets
  static const Color surfaceHigh = Color(0xFF262626); // inputs, tiles
  static const Color surfaceHighest = Color(0xFF2E2E2E); // elevated elements

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFFFFFF); // white — all interactive
  static const Color primaryMuted = Color(0xFF3A3A3A); // subtle tint backgrounds

  // ── On-colors ─────────────────────────────────────────────────────────────
  static const Color onBackground = Color(0xFFF0F0F0); // primary text
  static const Color onSurface = Color(0xFFB0B0B0); // secondary text
  static const Color onSurfaceMuted = Color(0xFF666666); // hints, placeholders
  static const Color onSurfaceDim = Color(0xFF333333); // dividers, borders

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5252);

  // ── Vault ─────────────────────────────────────────────────────────────────
  static const Color vaultActive = Color(0xFFFF5252); // secret vault indicator

  // ── App bar ───────────────────────────────────────────────────────────────
  static const Color appBarBackground = background;
  static const Color appBarTitle = onBackground;
  static const Color appBarIcon = onSurface;

  // ── Backward compat aliases ───────────────────────────────────────────────
  static const Color secondary = surfaceHigh;
  static const Color textPrimary = onBackground;
  static const Color textSecondary = onSurface;
  static const Color textDisabled = onSurfaceMuted;
  static const Color border = onSurfaceDim;
  static const Color backgroundAccent = surfaceHigh;
  static const Color backgroundDark = surfaceHighest;
  static const Color backgroundLight = surface;
  static const Color iconPrimary = onSurfaceMuted;
  static const Color buttonPrimary = primary;
  static const Color buttonDisabled = surfaceHigh;
}
