import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/ApiService.dart';
import 'MedicineScreen/medicine_scan_page.dart';

class ScanDocumentScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ScanDocumentScreen({super.key, this.userData});

  @override
  State<ScanDocumentScreen> createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();
  int _currentNavIndex = 1; // Default to scan screen
  static const int _maxRetries = 2;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90, // Increased for better quality
        maxWidth: 1600, // Increased for better OCR
        maxHeight: 1600,
      );

      if (pickedFile != null) {
        final compressedFile = await _compressImage(File(pickedFile.path));
        if (compressedFile != null) {
          final permanentFile = await _saveImagePermanently(compressedFile);
          setState(() => _image = permanentFile);
          debugPrint('Image saved successfully: ${permanentFile.path}');
        } else {
          throw Exception('Image compression failed');
        }
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Image picking error: $e');
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 80, // Increased quality for better OCR
        minWidth: 1000, // Adjusted for balance
        minHeight: 1000,
      );

      if (result == null) {
        debugPrint('Compression failed: No result returned');
        return null;
      }

      debugPrint('Image compressed successfully: ${result.path}');
      return File(result.path);
    } catch (e) {
      debugPrint('Compression error: $e');
      return null;
    }
  }

  Future<File> _saveImagePermanently(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${directory.path}/$fileName';
      final savedFile = await imageFile.copy(newPath);
      debugPrint('Image saved permanently at: $newPath');
      return savedFile;
    } catch (e) {
      debugPrint('Error saving image: $e');
      throw Exception('Failed to save image: $e');
    }
  }

  Future<void> _processImage() async {
    if (_image == null) {
      _showErrorSnackbar('Please select an image first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _apiService.uploadPrescription(_image!);
        if (!mounted) return;

        // Validate API response
        if (response['medicines'] == null ||
            response['extracted_text'] == null) {
          throw Exception('Invalid API response: Missing required fields');
        }

        debugPrint('API response: $response');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineScanPage(
              imageFile: _image!,
              scanData: {
                'medicines': List<String>.from(response['medicines'] ?? []),
                'extracted_text': response['extracted_text']?.toString() ?? '',
                'id': 'scan_${DateTime.now().millisecondsSinceEpoch}',
              },
            ),
          ),
        );
        return; // Success, exit retry loop
      } catch (e) {
        debugPrint('Attempt $attempt failed: $e');
        if (attempt == _maxRetries) {
          setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
          _showErrorSnackbar('Processing failed: ${_errorMessage!}');
        }
        await Future.delayed(Duration(seconds: attempt)); // Exponential backoff
      } finally {
        if (mounted && attempt == _maxRetries) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _currentNavIndex) return;

    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/dashboard',
            arguments: widget.userData);
        break;
      case 1: // Scan (current screen)
        break;
      case 2: // Profile
        Navigator.pushReplacementNamed(context, '/profile',
            arguments: widget.userData);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Prescription'),
        actions: [
          if (_image != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isProcessing
                  ? null
                  : () => setState(() {
                _image = null;
                _errorMessage = null;
              }),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _image != null
                    ? InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.file(_image!, fit: BoxFit.contain),
                )
                    : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 100, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No prescription selected',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _processImage,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        onPressed: _isProcessing
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        onPressed: _isProcessing
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processImage,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: _isProcessing
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    )
                        : const Text(
                      'Extract Medicines',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}