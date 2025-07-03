import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_multipart/form_data.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';
import 'package:shelf_multipart/multipart.dart';

void main() async {
  load(); // Load .env file
  final openAIApiKey = env['OPENAI_API_KEY'] ?? '';
  if (openAIApiKey.isEmpty) {
    print('Error: OPENAI_API_KEY not found in .env file');
    return;
  }

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler((request) => _router(request, openAIApiKey));

  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server running on ${server.address.host}:${server.port}');
}

FutureOr<Response> _router(Request request, String openAIApiKey) {
  if (request.method == 'POST' && request.url.path == 'upload') {
    return _handleUpload(request, openAIApiKey);
  }
  return Response.notFound('Not found');
}

Future<Response> _handleUpload(Request request, String openAIApiKey) async {
  if (!request.isMultipart) {
    return Response(400, body: 'Request must be multipart');
  }

  io.File? imageFile;
  try {
    await for (final formData in request.multipartFormData) {
      if (formData.name == 'file') {
        imageFile = io.File('temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final bytes = await formData.part.readBytes();
        await imageFile.writeAsBytes(bytes);
        print('Image received: ${bytes.length ~/ 1024} KB');
        break;
      }
    }

    if (imageFile == null) {
      return Response(400, body: 'No file uploaded');
    }

    // Encode image directly as base64 instead of uploading
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final gptResponse = await queryGPTWithImage(base64Image, openAIApiKey);

    return Response.ok(
      jsonEncode({
        'medicines': gptResponse['medicines'],
        'extracted_text': gptResponse['extracted_text']
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e, stackTrace) {
    print('Error processing upload: $e\n$stackTrace');
    return Response(500, body: 'Error processing image: ${e.toString()}');
  } finally {
    if (imageFile != null && await imageFile.exists()) {
      try {
        await imageFile.delete();
        print('Temporary file deleted: ${imageFile.path}');
      } catch (e) {
        print('Failed to delete temporary file: $e');
      }
    }
  }
}

Future<Map<String, dynamic>> queryGPTWithImage(String base64Image, String openAIApiKey) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final headers = {
    'Authorization': 'Bearer $openAIApiKey',
    'Content-Type': 'application/json',
  };

  final body = jsonEncode({
    "model": "gpt-4-turbo",
    "response_format": { "type": "json_object" },
    "messages": [
      {
        "role": "system",
        "content": '''
        You are a medical prescription analyzer. Extract medicine names and dosage information.
        Return JSON format exactly like this:
        {
          "medicines": ["Medicine 1 500mg", "Medicine 2 200mg"],
          "extracted_text": "Full prescription text"
        }
        '''
      },
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "Extract all medicine names with their dosages from this prescription."
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "data:image/jpeg;base64,$base64Image" // Direct base64 embedding
            }
          }
        ]
      }
    ],
    "max_tokens": 1000,
    "temperature": 0.1
  });

  final response = await http.post(url, headers: headers, body: body)
      .timeout(const Duration(seconds: 30));

  if (response.statusCode == 200) {
    final responseBody = jsonDecode(response.body);
    final content = jsonDecode(responseBody['choices'][0]['message']['content']);

    return {
      'medicines': List<String>.from(content['medicines'] ?? []),
      'extracted_text': content['extracted_text']?.toString() ?? ''
    };
  } else {
    throw Exception('API error: ${response.statusCode} - ${response.body}');
  }
}