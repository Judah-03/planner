import 'package:flutter/material.dart';

class AppColors {
  // Professional Indigo & Slate Palette
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color secondary = Color(0xFF6366F1); // Indigo 500
  static const Color accent = Color(0xFF312E81); // Indigo 900
  
  // Backgrounds with Professional Depth
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  
  // Status Colors (Standard Professional)
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9); // Sky 500
  
  // Subdued Professional Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF4338CA)], // Indigo 600 -> Indigo 700
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], // Indigo 500 -> Indigo 600
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)], // Slate 800 -> Slate 700
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
