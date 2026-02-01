import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_header.dart';
import '../widgets/pet_selector.dart';
import '../widgets/vaccine_card.dart';
import '../repositories/vaccine_repository.dart';
import '../services/ocr_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class UploadVaccineScreen extends StatefulWidget {
  const UploadVaccineScreen({super.key});

  @override
  State<UploadVaccineScreen> createState() => _UploadVaccineScreenState();
}

class _UploadVaccineScreenState extends State<UploadVaccineScreen> {
  int _selectedPetIndex = 0;
  List<dynamic> _petsData = [];
  List<String> _petNames = [];
  List<dynamic> _vaccines = [];
  bool _isLoading = true;

  // Animation state
  final ScrollController _scrollController = ScrollController();
  bool _isBottomBarVisible = true;

  // Offline support
  final VaccineRepository _repository = VaccineRepository();
  final OcrService _ocrService = OcrService();
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final SyncService _syncService = SyncService.instance;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<bool>? _syncSubscription;
  bool _isOffline = false;
  int _pendingUploads = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);

    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.connectionStatus.listen((
      isConnected,
    ) {
      setState(() {
        _isOffline = !isConnected;
      });
      if (isConnected) {
        _loadData(); // Refresh data when back online
        _updatePendingCount();
      }
    });

    // Monitor sync status
    _syncSubscription = _syncService.syncStatus.listen((isSyncing) {
      if (!isSyncing && mounted) {
        // Sync finished, refresh everything
        _loadData();
        _updatePendingCount();
      }
    });

    _updatePendingCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  double _lastScrollOffset = 0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final diff = currentOffset - _lastScrollOffset;

    // Always show if at top (allow for bounce)
    if (currentOffset <= 0) {
      if (!_isBottomBarVisible) {
        setState(() => _isBottomBarVisible = true);
      }
      _lastScrollOffset = currentOffset;
      return;
    }

    // Hide when scrolling down
    if (diff > 0 && _isBottomBarVisible) {
      setState(() => _isBottomBarVisible = false);
    }
    // Show when scrolling up
    else if (diff < 0 && !_isBottomBarVisible) {
      setState(() => _isBottomBarVisible = true);
    }

    _lastScrollOffset = currentOffset;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pets = await _repository.getPets();

    if (pets.isNotEmpty) {
      _petsData = pets;
      _petNames = pets.map((p) => p['name'] as String).toList();
      await _loadVaccines(pets[0]['id']);
    } else {
      _petsData = [];
      _petNames = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVaccines(int petId) async {
    final vaccines = await _repository.getVaccines(petId);
    setState(() {
      _vaccines = vaccines;
    });
  }

  Future<void> _updatePendingCount() async {
    final count = await _syncService.getPendingCount();
    if (mounted) {
      setState(() {
        _pendingUploads = count;
      });
    }
  }

  Future<void> _handleUpload() async {
    try {
      final File? image = await _ocrService.pickImage();
      if (image == null) return;

      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkGreen),
          ),
        ),
      );

      final data = await _ocrService.extractVaccineData(image);

      // Hide loading dialog
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      // Show confirmation dialog
      await showDialog(
        context: context,
        builder: (context) => _buildConfirmDialog(data, image),
      );
    } catch (e) {
      // Hide loading dialog if error occurs
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildConfirmDialog(Map<String, String> data, File image) {
    final nameController = TextEditingController(text: data['vaccineName']);
    final dateController = TextEditingController(text: data['dateIssued']);
    final dueController = TextEditingController(text: data['nextDueDate']);
    final typeController = TextEditingController(
      text: data['category'] ?? 'Vaccination',
    );

    InputDecoration customInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.textGrey,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.darkGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Confirm Details',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: AppColors.textBlack,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(image, height: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textBlack,
              ),
              cursorColor: AppColors.darkGreen,
              decoration: customInputDecoration('Vaccine Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeController,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textBlack,
              ),
              cursorColor: AppColors.darkGreen,
              decoration: customInputDecoration('Type / Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textBlack,
              ),
              cursorColor: AppColors.darkGreen,
              decoration: customInputDecoration('Date Issued'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dueController,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textBlack,
              ),
              cursorColor: AppColors.darkGreen,
              decoration: customInputDecoration('Next Due Date'),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.darkGreen,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            // Validate required fields
            if (nameController.text.trim().isEmpty ||
                dateController.text.trim().isEmpty ||
                dueController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'All fields (Name, Issued Date, Due Date) are required',
                  ),
                ),
              );
              return;
            }

            Navigator.pop(context);
            if (_petsData.isEmpty) return;

            final petId = _petsData[_selectedPetIndex]['id'];
            final String? serverImageUrl = data['imageUrl'];

            final Map<String, String> payload = {
              'petId': petId.toString(),
              'vaccineName': nameController.text.trim(),
              'dateIssued': dateController.text.trim(),
              'nextDueDate': dueController.text.trim(),
              'type': typeController.text.trim().isEmpty
                  ? 'Vaccination'
                  : typeController.text.trim(),
            };

            if (serverImageUrl != null && serverImageUrl.isNotEmpty) {
              payload['imageUrl'] = serverImageUrl;
            }

            print('Upload payload: $payload'); // Debug log

            // Only upload file if we don't have a server URL
            final File? fileToUpload =
                (serverImageUrl != null && serverImageUrl.isNotEmpty)
                ? null
                : image;

            final success = await _repository.uploadVaccine(
              payload,
              fileToUpload,
            );

            if (mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isOffline
                          ? 'Record saved! Will sync when online'
                          : 'Record added successfully!',
                    ),
                  ),
                );
                _loadVaccines(petId);
                _updatePendingCount();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to add record')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Main Body with Scrollable List
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
                    // Offline indicator
                    if (_isOffline || _pendingUploads > 0)
                      Container(
                        width: double.infinity,
                        color: _isOffline ? Colors.orange : Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isOffline ? Icons.cloud_off : Icons.sync,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOffline
                                  ? 'Offline mode - Changes will sync when online'
                                  : 'Syncing $_pendingUploads pending upload${_pendingUploads > 1 ? "s" : ""}...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _petNames.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'No pets found. Please go online once to sync your pets.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : PetSelector(
                              pets: _petNames,
                              selectedIndex: _selectedPetIndex,
                              onPetSelected: (index) {
                                setState(() {
                                  _selectedPetIndex = index;
                                });
                                _loadVaccines(_petsData[index]['id']);
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
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : RefreshIndicator(
                            onRefresh: () => _loadVaccines(
                              _petsData[_selectedPetIndex]['id'],
                            ),
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                top: 24,
                                left: 20,
                                right: 20,
                                bottom:
                                    200, // Make extra space for the bottom bar so last item isn't obscured
                              ),
                              itemCount: _vaccines.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final vac = _vaccines[index];
                                return VaccineCard(
                                  dateIssued: vac['dateIssued'] ?? '',
                                  type: vac['type'] ?? 'Vaccination',
                                  title: vac['vaccineName'] ?? 'Unknown',
                                  nextDueDate: vac['nextDueDate'] ?? '',
                                  headerColor: (vac['type'] == 'Deworming')
                                      ? AppColors.dewormingBg
                                      : AppColors.vaccinationBg,
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),

          // Sliding Bottom Action Area
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: _isBottomBarVisible ? 0 : -200, // Hide by moving down
            left: 0,
            right: 0,
            child: Container(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _handleUpload,
                      child: Container(
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
          ),

          // Scroll to view chip
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: _isBottomBarVisible ? 185 : -100, // Move with the bar
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
                      angle: -1.5708,
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
