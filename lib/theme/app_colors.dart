import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(
    0x33CEE38C,
  ); // Opacity 0.2 approx from 33 hex
  static const Color darkGreen = Color(
    0xFF0D302C,
  ); // Updated to match Figma #0D302C
  static const Color petChipBorder = Color(0x4DDFDEFF); // Old
  static const Color petChipUnselectedBorder = Color(
    0xFFE4E5F0,
  ); // Exact Figma #E4E5F0
  static const Color textBlack = Color(0xFF191C1B); // Standard dark text
  static const Color textGrey = Color(0xFF3F4945); // Muted text
  static const Color white = Colors.white;

  // Card Headers
  static const Color vaccinationBg = Color(0x338B5CF6);
  static const Color dewormingBg = Color(0x33529AE6);

  // Specific styling
  static const Color chipUnselectedBg = Colors.white;
  static const Color chipSelectedBg = darkGreen;
  static const Color chipUnselectedText = textBlack;
  static const Color chipSelectedText = Colors.white;

  static const Color borderGrey = Color(0xFFF1F1F1);
  static const Color solidBackground = Color(
    0xFFF5F9E8,
  ); // Solid version of soft green
  static const Color backButtonBg = Color(0x4DDFDEFF); // 30% opacity of #DFDEFF
}
