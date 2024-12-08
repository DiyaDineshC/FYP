import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart'; // For setting content type

class ApiService {
  static const String _baseUrl = 'http://192.168.1.3:5000/predict';

  static Future<void> uploadImage(File imageFile) async {
    final String url = '$_baseUrl/predict';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: basename(imageFile.path),
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await http.Response.fromStream(response);
        print('Success: ${responseBody.body}');
        // Process the response data as needed
      } else {
        print('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }
}
