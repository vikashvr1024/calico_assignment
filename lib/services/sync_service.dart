import 'dart:async';
import '../repositories/vaccine_repository.dart';
import '../services/connectivity_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  final VaccineRepository _repository = VaccineRepository();
  final ConnectivityService _connectivity = ConnectivityService.instance;

  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  SyncService._internal() {
    // Listen to connectivity changes and auto-sync
    _connectivity.connectionStatus.listen((isConnected) {
      if (isConnected) {
        syncAll();
      }
    });

    // Initial sync check is handled by the listener if it emits current state,
    // but we can call it once safely here too.
    syncAll();
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      final isOnline = await _connectivity.checkConnection();
      if (!isOnline) {
        _isSyncing = false;
        return;
      }

      _syncStatusController.add(true); // Sync started
      print('Starting sync...');

      // Explicitly awaiting the Future<int> from repository
      final int successCount = await _repository.syncPendingUploads();

      if (successCount > 0) {
        print('Successfully synced $successCount items. Clearing cache...');
        await _repository.clearCache();
      }
      print('Sync completed successfully');
    } catch (e) {
      print('Sync failed: $e');
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false); // Sync finished
    }
  }

  void dispose() {
    _syncStatusController.close();
  }

  Future<int> getPendingCount() async {
    return await _repository.getPendingUploadsCount();
  }
}
