import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const CustomHeader({super.key, required this.title, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, // Sufficient height for the header area
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      // Use Stack to avoid row overflow when elements are wide (80 + 196 + 80 > 335)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button: Top 60px (global) -> 16px (local in 64px height w/ 44px spacer)
          // Left 20px (global) -> 0px (local in padded container)
          Positioned(
            left: 0,
            top: 16,
            child: GestureDetector(
              onTap: onBackPressed,
              child: Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.backButtonBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.backButtonBg, width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Color(0xFF000000),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'back',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000000),
                        height: 18 / 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title: Top 66px (global) -> 22px (local)
          // Left 108px (global) -> 88px (local in padded container)
          // Width 196px
          Positioned(
            left: 88,
            top: 22,
            child: SizedBox(
              width: 196,
              height: 20,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                  height: 18 / 14, // 129%
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
