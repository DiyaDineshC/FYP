import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart'; // Import your API service class

class ImagePickerService {
  static Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await ApiService.uploadImage(imageFile); // Call the upload function
    } else {
      print('No image selected.');
    }
  }
}
