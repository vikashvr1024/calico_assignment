import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PetSelector extends StatelessWidget {
  final List<String> pets;
  final int selectedIndex;
  final ValueChanged<int> onPetSelected;

  const PetSelector({
    super.key,
    required this.pets,
    required this.selectedIndex,
    required this.onPetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
        ), // Parent handles padding or positioned
        itemCount: pets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onPetSelected(index),
            child: Container(
              width: isSelected ? 112 : 106, // Fixed widths from Figma
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.darkGreen
                    : const Color(0x4DDFDEFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE4E5F0)
                      : const Color(0x4DDFDEFF),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pets[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.white : Colors.black,
                      height: 18 / 13,
                      letterSpacing: 0,
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.close : Icons.add,
                    size: 14,
                    color: isSelected ? AppColors.white : Colors.black,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
