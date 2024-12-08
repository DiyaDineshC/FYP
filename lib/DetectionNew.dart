import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelmetLicensePlateDetection extends StatefulWidget {
  @override
  _HelmetLicensePlateDetectionState createState() =>
      _HelmetLicensePlateDetectionState();
}

class _HelmetLicensePlateDetectionState extends State<HelmetLicensePlateDetection> {
File? _image;
  List _detections = [];  // Initialize as an empty list
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer(); // Use GoogleMlKit

  late Interpreter _interpreter;

  // Firebase Storage reference
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Load the YOLO model using the TensorFlow Lite Interpreter
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
  }

  // Preprocess the image for YOLO inference (resize and normalize)
  Future<void> runDetection(File image) async {
    setState(() {
      _loading = true;
    });

    try {
      var imgData = await _loadImage(image);

      // Make sure the image is passed correctly
      print("Running inference...");

      var output = List.filled(1 * 8400, 0);
      _interpreter.run(imgData, output);

      print("Inference done.");

      setState(() {
        _detections = output;
        _loading = false;
      });
    } catch (e) {
      print("Error during detection: $e");
      setState(() {
        _loading = false;
      });
    }
  }


  // Load and preprocess the image (resize and normalize)
  Future<List<dynamic>> _loadImage(File image) async {
    img.Image imageFile = img.decodeImage(await image.readAsBytes())!;
    img.Image resized = img.copyResize(imageFile, width: 640, height: 640);

    // Normalize and convert the image to a list of floats (if required by your model)
    List<double> normalizedData = [];
    for (var pixel in resized.getBytes()) {
      // Example normalization (if needed, based on your model's requirements)
      normalizedData.add(pixel / 255.0); // Normalize to [0, 1] range
    }

    return normalizedData;
  }

  // Extract text using OCR from license plate
  Future<String> extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Initialize _image here
      });
      await runDetection(_image!); // Use _image safely after initialization

      // Extract license plate text
      String plateText = await extractText(_image!);

      // Upload image to Firebase Storage and get the image URL
      String imageUrl = await _uploadImage(_image!);

      // Store detection data in Firestore
      await _storeDetectionData(imageUrl, plateText);
    }
  }

  // Upload image to Firebase Storage and return the URL
  Future<String> _uploadImage(File image) async {
    try {
      final storageRef = _storage.ref().child('images/${DateTime.now()}.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  // Store detection data in Firestore
  Future<void> _storeDetectionData(String imageUrl, String plateText) async {
    try {
      await _firestore.collection('detections').add({
        'imageUrl': imageUrl, // URL of the uploaded image
        'plateText': plateText, // Detected license plate text
        'timestamp': Timestamp.now(), // Timestamp of the detection
      });
      print("Detection data stored successfully.");
    } catch (e) {
      print('Error storing detection data: $e');
    }
  }
  // Show results with bounding boxes and labels
  Widget showResults() {
    if (_image == null) {
      return Center(child: Text("No image selected.")); // Show message if _image is null
    } else {
      return Stack(
        children: [
          Image.file(_image!),
          for (var detection in _detections)
            Positioned(
              left: detection['rect']['x'] * MediaQuery.of(context).size.width,
              top: detection['rect']['y'] * MediaQuery.of(context).size.height,
              width: detection['rect']['w'] * MediaQuery.of(context).size.width,
              height: detection['rect']['h'] * MediaQuery.of(context).size.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    detection['label'],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    _interpreter.close(); // Close the interpreter when done
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Helmet and License Plate Detection")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              CircularProgressIndicator()
            else if (_image != null)
              Expanded(child: showResults())
            else
              Text("No image selected."),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick an image"),
            ),
          ],
        ),
      ),
    );
  }
}

