import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String _baseUrl = 'http://10.1.31.11:8080/upload';
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  Future<Map<String, dynamic>> uploadPrescription(File imageFile) async {
    // Validate input
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

    // Compress image
    final compressedFile = await _compressImage(imageFile);
    if (compressedFile == null) {
      throw Exception('Image compression failed');
    }

    try {
      // Log sizes
      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();
      print('Original: ${originalSize ~/ 1024}KB, Compressed: ${compressedSize ~/ 1024}KB');

      // Upload with retries
      return await _uploadWithRetry(compressedFile);
    } finally {
      // Clean up
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }
    }
  }

  Future<File?> _compressImage(File original) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        original.path,
        targetPath,
        quality: 60,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Compression error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _uploadWithRetry(File file) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < _maxRetries) {
      try {
        final uri = Uri.parse(_baseUrl);
        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ));

        print('Upload attempt ${attempt + 1}');
        final response = await request.send().timeout(const Duration(seconds: 30));
        final body = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final json = jsonDecode(body) as Map<String, dynamic>;
          return {
            'medicines': List<String>.from(json['medicines'] ?? []),
            'extracted_text': json['extracted_text']?.toString() ?? '',
          };
        } else {
          throw Exception('Server error: ${response.statusCode} - $body');
        }
      } on TimeoutException catch (e) {
        lastError = e;
        print('Timeout: $e');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('Error: $e');
      }

      attempt++;
      if (attempt < _maxRetries) {
        await Future.delayed(_initialRetryDelay * (1 << attempt));
      }
    }

    throw lastError ?? Exception('Upload failed after $_maxRetries attempts');
  }
}