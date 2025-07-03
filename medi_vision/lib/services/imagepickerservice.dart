import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'image_database_helper.dart'; // Import your SQLite helper

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery and store it in SQLite
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Get current user ID from Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Store the image with userId in SQLite
          await ImageDatabaseHelper().insertImage(file.path, user.uid);
        }

        return file;
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }
}
