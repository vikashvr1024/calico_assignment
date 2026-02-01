import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

/// Service for analyzing vaccine images via Backend AI (OpenRouter).
class OcrService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// Sends image to backend for AI analysis and returns structured data.
  Future<Map<String, String>> extractVaccineData(File imageFile) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/vaccines/analyze');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print('Sending image to backend for analysis: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Backend Response Code: ${response.statusCode}');
      print('Backend Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'];
          return {
            'vaccineName': data['vaccineName']?.toString() ?? '',
            'category': data['category']?.toString() ?? 'Vaccination',
            'dateIssued': data['dateIssued']?.toString() ?? '',
            'nextDueDate': data['nextDueDate']?.toString() ?? '',
            'imageUrl': data['imageUrl']?.toString() ?? '',
          };
        }
      }

      return _emptyResult();
    } catch (e) {
      print('AI Analysis Error: $e');
      return _emptyResult();
    }
  }

  Map<String, String> _emptyResult() => {
    'vaccineName': '',
    'category': 'Vaccination',
    'dateIssued': '',
    'nextDueDate': '',
  };
}
