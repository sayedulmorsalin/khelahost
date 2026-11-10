import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service to upload tournament screenshots/images to free image hosting APIs.
/// Uses Freeimage.host as primary and Catbox.moe as resilient zero-config fallback.
class ImageUploadService {
  static const String _freeImageHostKey = '6d207e02198a847aa98d0a2a901485a5';

  /// Uploads an [XFile] (from ImagePicker) and returns the public hosted image URL.
  static Future<String> uploadXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'screenshot_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadBytes(bytes, fileName: name);
  }

  /// Uploads raw image bytes to a free image hosting API.
  static Future<String> uploadBytes(
    Uint8List bytes, {
    String fileName = 'proof.jpg',
  }) async {
    // Attempt 1: Freeimage.host
    try {
      final url = await _uploadToFreeImageHost(bytes, fileName);
      if (url.isNotEmpty) return url;
    } catch (e) {
      // Freeimage failed, proceed to Catbox fallback
    }

    // Attempt 2: Catbox.moe (zero-config, high uptime, permanent hosting)
    try {
      final url = await _uploadToCatbox(bytes, fileName);
      if (url.isNotEmpty) return url;
    } catch (e) {
      throw Exception('Image upload failed across free host providers: $e');
    }

    throw Exception('Failed to get public URL from image host providers.');
  }

  static Future<String> _uploadToFreeImageHost(
    Uint8List bytes,
    String fileName,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://freeimage.host/api/1/upload'),
    );
    request.fields['key'] = _freeImageHostKey;
    request.fields['action'] = 'upload';
    request.fields['format'] = 'json';
    request.files.add(
      http.MultipartFile.fromBytes('source', bytes, filename: fileName),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final url = data['image']?['url']?.toString();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    throw Exception('Freeimage.host returned status ${response.statusCode}');
  }

  static Future<String> _uploadToCatbox(
    Uint8List bytes,
    String fileName,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://catbox.moe/user/api.php'),
    );
    request.fields['reqtype'] = 'fileupload';
    request.files.add(
      http.MultipartFile.fromBytes('fileToUpload', bytes, filename: fileName),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final result = response.body.trim();
      if (result.startsWith('http://') || result.startsWith('https://')) {
        return result;
      }
    }
    throw Exception('Catbox returned status ${response.statusCode}: ${response.body}');
  }
}

