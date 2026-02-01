import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

class VaccineRepository {
  final ApiService _apiService = ApiService();
  final AppDatabase _db = AppDatabase.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

  // Fetch pets (online-first, fallback to cache)
  Future<List<dynamic>> getPets() async {
    final isOnline = await _connectivity.checkConnection();

    if (isOnline) {
      try {
        final pets = await _apiService.fetchPets();
        await _cachePets(pets);
        return pets;
      } catch (e) {
        print('API failed, falling back to cache: $e');
        return await _getCachedPets();
      }
    } else {
      print('Offline mode: Loading pets from cache');
      return await _getCachedPets();
    }
  }

  // Fetch vaccines (online-first, fallback to cache)
  Future<List<dynamic>> getVaccines(int petId) async {
    final isOnline = await _connectivity.checkConnection();

    if (isOnline) {
      try {
        final vaccines = await _apiService.fetchVaccines(petId);
        await _cacheVaccines(vaccines, petId);
        return vaccines;
      } catch (e) {
        print('API failed, falling back to cache: $e');
        return await _getCachedVaccines(petId);
      }
    } else {
      print('Offline mode: Loading vaccines from cache');
      return await _getCachedVaccines(petId);
    }
  }

  // Upload vaccine (queue if offline)
  Future<bool> uploadVaccine(Map<String, String> data, File? image) async {
    final isOnline = await _connectivity.checkConnection();

    if (isOnline) {
      try {
        final success = await _apiService.uploadVaccine(data, image);
        if (success) {
          print('Vaccine uploaded successfully');
        }
        return success;
      } catch (e) {
        print('Upload failed, queuing for later: $e');
        await _queueForUpload(data, image);
        await _saveLocalVaccine(data);
        return true;
      }
    } else {
      print('Offline mode: Queuing vaccine for upload');
      await _queueForUpload(data, image);
      await _saveLocalVaccine(data);
      return true;
    }
  }

  // Sync all pending uploads, returns number of successful syncs
  Future<int> syncPendingUploads() async {
    final isOnline = await _connectivity.checkConnection();
    if (!isOnline) {
      print('Cannot sync: Still offline');
      return 0;
    }

    final database = await _db.database;
    final pending = await database.query('pending_uploads');

    if (pending.isEmpty) return 0;

    print('Syncing ${pending.length} pending uploads...');
    int successCount = 0;

    for (var item in pending) {
      try {
        final data =
            jsonDecode(item['vaccine_data'] as String) as Map<String, dynamic>;
        final imagePath = item['image_path'] as String?;

        File? imageFile;
        if (imagePath != null && imagePath.isNotEmpty) {
          imageFile = File(imagePath);
          if (!await imageFile.exists()) {
            imageFile = null;
          }
        }

        final success = await _apiService.uploadVaccine(
          data.map((key, value) => MapEntry(key, value.toString())),
          imageFile,
        );

        if (success) {
          await database.delete(
            'pending_uploads',
            where: 'id = ?',
            whereArgs: [item['id']],
          );
          print('Synced pending upload ${item['id']}');
          successCount++;
        }
      } catch (e) {
        print('Failed to sync upload ${item['id']}: $e');
      }
    }
    return successCount;
  }

  // Clear local cache to force refresh from server
  Future<void> clearCache() async {
    final database = await _db.database;
    await database.delete('pets');
    await database.delete('vaccines');
    print('Local cache cleared');
  }

  // Get count of pending uploads
  Future<int> getPendingUploadsCount() async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM pending_uploads',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Private helper methods
  Future<void> _cachePets(List<dynamic> pets) async {
    final database = await _db.database;
    for (var pet in pets) {
      await database.insert('pets', {
        'id': pet['id'],
        'name': pet['name'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('Cached ${pets.length} pets');
  }

  Future<List<dynamic>> _getCachedPets() async {
    final database = await _db.database;
    final result = await database.query('pets');
    print('Loaded ${result.length} pets from cache');
    return result;
  }

  Future<void> _cacheVaccines(List<dynamic> vaccines, int petId) async {
    final database = await _db.database;

    // Clear old vaccines for this pet
    await database.delete('vaccines', where: 'pet_id = ?', whereArgs: [petId]);

    for (var vaccine in vaccines) {
      await database.insert('vaccines', {
        'server_id': vaccine['id'],
        'pet_id': petId,
        'vaccine_name': vaccine['vaccineName'],
        'date_issued': vaccine['dateIssued'],
        'next_due_date': vaccine['nextDueDate'],
        'type': vaccine['type'],
        'image_url': vaccine['imageUrl'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    print('Cached ${vaccines.length} vaccines for pet $petId');
  }

  Future<List<dynamic>> _getCachedVaccines(int petId) async {
    final database = await _db.database;
    final result = await database.query(
      'vaccines',
      where: 'pet_id = ?',
      whereArgs: [petId],
    );

    return result
        .map(
          (row) => {
            'id': row['server_id'],
            'vaccineName': row['vaccine_name'],
            'dateIssued': row['date_issued'],
            'nextDueDate': row['next_due_date'],
            'type': row['type'],
            'imageUrl': row['image_url'],
          },
        )
        .toList();
  }

  Future<void> _queueForUpload(Map<String, String> data, File? image) async {
    final database = await _db.database;
    await database.insert('pending_uploads', {
      'vaccine_data': jsonEncode(data),
      'image_path': image?.path ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });
    print('Queued vaccine for upload');
  }

  Future<void> _saveLocalVaccine(Map<String, String> data) async {
    final database = await _db.database;
    await database.insert('vaccines', {
      'pet_id': int.parse(data['petId'] ?? '0'),
      'vaccine_name': data['vaccineName'] ?? '',
      'date_issued': data['dateIssued'] ?? '',
      'next_due_date': data['nextDueDate'] ?? '',
      'type': data['type'] ?? 'Vaccination',
      'image_url': data['imageUrl'] ?? '',
      'synced': 0,
    });
    print('Saved vaccine locally');
  }
}
