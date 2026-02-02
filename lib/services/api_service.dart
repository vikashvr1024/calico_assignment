import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  // Use localhost for iOS simulator
  // Use your machine's IP for physical device
  static const String baseUrl = 'http://0.0.0.0:3000/api';

  Future<List<dynamic>> fetchPets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pets'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load pets');
      }
    } catch (e) {
      print('Error fetching pets: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchVaccines(int petId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vaccines?petId=$petId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load vaccines');
      }
    } catch (e) {
      print('Error fetching vaccines: $e');
      return [];
    }
  }

  Future<bool> uploadVaccine(Map<String, String> data, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/vaccines'),
      );

      request.fields.addAll(data);

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'certificate',
            imageFile.path,
            contentType: MediaType(
              'image',
              'jpeg',
            ), // Adjust based on file type if needed
          ),
        );
      }

      var streamwedResponse = await request.send();
      var response = await http.Response.fromStream(streamwedResponse);

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Upload failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error uploading vaccine: $e');
      return false;
    }
  }
}
