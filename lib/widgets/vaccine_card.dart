import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import 'package:intl/intl.dart';

class VaccineCard extends StatelessWidget {
  final String dateIssued;
  final String type; // Vaccination or Deworming
  final String title;
  final String nextDueDate;
  final Color headerColor;

  const VaccineCard({
    super.key,
    required this.dateIssued,
    required this.type,
    required this.title,
    required this.nextDueDate,
    required this.headerColor,
  });

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (e) {
      return dateStr; // Return as-is if not ISO format (e.g. already formatted)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.zero, // Sharp corners for medical UI
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 30,
          bottom: 30,
          left: 12,
          right: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'Issued date: ${_formatDate(dateIssued)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 18 / 13, // 138%
                  color: Color(0xFF000000),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Vaccine details section with sharp corners
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: AppColors.borderGrey,
                ), // Exact #F1F1F1
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section (Frame 1136 specs)
                  Container(
                    width: double.infinity,
                    height: 38,
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: 10,
                      right: 64,
                    ),
                    decoration: BoxDecoration(
                      color: headerColor,
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.borderGrey,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 18 / 12,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                  // Title row (e.g., Anti Rabies - Frame 1139 specs)
                  Container(
                    width: double.infinity,
                    height: 38,
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: 10,
                      right: 64,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderGrey,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 18 / 13,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Next Due date row (Frame 1140 specs)
                  Row(
                    children: [
                      // Label half
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            border: Border(
                              right: BorderSide(
                                color: AppColors.borderGrey,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Next Due date',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 18 / 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      // Value half
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                          ),
                          child: Text(
                            _formatDate(nextDueDate),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 18 / 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
