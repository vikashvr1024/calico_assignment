import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_header.dart';
import '../widgets/pet_selector.dart';
import '../widgets/vaccine_card.dart';

class UploadVaccineScreen extends StatefulWidget {
  const UploadVaccineScreen({super.key});

  @override
  State<UploadVaccineScreen> createState() => _UploadVaccineScreenState();
}

class _UploadVaccineScreenState extends State<UploadVaccineScreen> {
  int _selectedPetIndex = 0;
  final List<String> _pets = ['Max', 'Shasha', 'Tyson'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Bottom area is white
      body: Stack(
        children: [
          Column(
            children: [
              // Fixed Opaque Top Section
              Container(
                color: AppColors.solidBackground,
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  children: [
                    CustomHeader(
                      title: 'Upload vaccine',
                      onBackPressed: () {
                        // Handle back press
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PetSelector(
                        pets: _pets,
                        selectedIndex: _selectedPetIndex,
                        onPetSelected: (index) {
                          setState(() {
                            _selectedPetIndex = index;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: IgnorePointer(
                    ignoring: false,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(overscroll: true),
                      child: Theme(
                        data: ThemeData(
                          colorScheme: ColorScheme.fromSwatch().copyWith(
                            secondary: const Color(0xFFF1F1F1),
                          ),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.only(
                            top: 24,
                            left: 20,
                            right: 20,
                            bottom: 140,
                          ),
                          children: const [
                            VaccineCard(
                              dateIssued: '17.02.2025',
                              type: 'Vaccination',
                              title: 'Ani Rabies',
                              nextDueDate: '11.06.2025',
                              headerColor: AppColors.vaccinationBg,
                            ),
                            SizedBox(height: 10),
                            VaccineCard(
                              dateIssued: '17.02.2025',
                              type: 'Deworming',
                              title: 'Ani Rabies',
                              nextDueDate: '11.06.2025',
                              headerColor: AppColors.dewormingBg,
                            ),
                            SizedBox(height: 10),
                            VaccineCard(
                              dateIssued: '17.02.2025',
                              type: 'Vaccination',
                              title: 'Ani Rabies',
                              nextDueDate: '11.06.2025',
                              headerColor: AppColors.vaccinationBg,
                            ),
                            SizedBox(height: 10),
                            VaccineCard(
                              dateIssued: '17.02.2025',
                              type: 'Deworming',
                              title: 'Ani Rabies',
                              nextDueDate: '11.06.2025',
                              headerColor: AppColors.dewormingBg,
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom Action Area (White Background)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.borderGrey, width: 1.0),
                  ),
                ),
                padding: const EdgeInsets.only(
                  bottom: 32,
                  top: 65,
                  left: 24,
                  right: 24,
                ),
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.darkGreen,
                          borderRadius: BorderRadius.circular(36),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pick your pet and upload the vaccination\ncertificate by adding a photo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          height: 20 / 12,
                          color: AppColors.textBlack,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Scroll to view chip - positioned above everything
          Positioned(
            bottom: 185, // Moved down from 225px
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 132,
                height: 32,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -1.5708, // -90 degrees in radians
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Scroll to view',
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
        ],
      ),
    );
  }
}
