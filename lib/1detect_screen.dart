import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:developer';
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectScreen extends StatefulWidget {
  final String? imagePath;
  final String? model;
  final List<CameraDescription> cameras;

  const DetectScreen({Key? key, this.imagePath, this.model, required this.cameras}) : super(key: key);

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  Interpreter? interpreter;
  String result = "Processing...";

  @override
  void initState() {
    super.initState();
    loadModelAndProcessImage();
  }

  Future<void> loadModelAndProcessImage() async {
    if (widget.imagePath != null) {
      try {
        // Load the appropriate model based on the selected type
        interpreter = await Interpreter.fromAsset("assets/best_float32.tflite");
        log("Model loaded: ${widget.model}");

        // Process the image and perform inference
        String output = await processImage(widget.imagePath!);
        setState(() {
          result = output;  // Display the detection result
        });
      } catch (e) {
        log("Failed to load model or process image: $e");
        setState(() {
          result = "Error in processing image.";
        });
      }
    }
  }

Future<String> processImage(String imagePath) async {
  // Load the image as a Uint8List from the file path
  final File imageFile = File(imagePath);
  final Uint8List imageBytes = await imageFile.readAsBytes();
  img.Image? image = img.decodeImage(imageBytes);

  if (image == null) {
    return "Failed to decode image";
  }

  // Resize the image to 640x640
  image = img.copyResize(image, width: 640, height: 640);

  // Convert image to a format compatible with TensorFlow Lite model input
  var input = List.generate(640 * 640 * 3, (i) => 0.0).reshape([1, 640, 640, 3]);

  for (int x = 0; x < 640; x++) {
    for (int y = 0; y < 640; y++) {
      final pixel = image.getPixel(x, y);
      input[0][x][y][0] = (img.getRed(pixel) / 255.0); // Normalize RGB channels
      input[0][x][y][1] = (img.getGreen(pixel) / 255.0);
      input[0][x][y][2] = (img.getBlue(pixel) / 255.0);
    }
  }

  // Define an output buffer for the model’s predictions
  var output = List.filled(7 * 8400, 0.0).reshape([1, 7, 8400]); // Correct shape for output

  // Run the model
  interpreter?.run(input, output);

  // Process the model's output
  String detectionResults = "Detected items:\n";
  List<String> labels = ["Helmet", "No Helmet", "License Plate", "Other 1", "Other 2", "Other 3", "Other 4"]; // Update labels if necessary

  // Loop through the output shape [1, 7, 8400]
  for (int i = 0; i < 7; i++) { // Iterate through the first dimension (classes)
    for (int j = 0; j < 8400; j++) { // Iterate through the second dimension (detections)
      double confidence = output[0][i][j]; // Confidence score for the detection
      if (confidence > 0.5) { // Confidence threshold
        // Assuming your model provides bounding boxes in a certain format,
        // adjust indices accordingly based on the model's output specification
        double xMin = output[0][i][j] * 640; // Modify index based on your model's output layout
        double yMin = output[0][i][j + 1] * 640; // Example; adjust as necessary
        double xMax = output[0][i][j + 2] * 640; // Example; adjust as necessary
        double yMax = output[0][i][j + 3] * 640; // Example; adjust as necessary

        detectionResults += "${labels[i]} detected with confidence $confidence\n";
        detectionResults += "Bounding box: [($xMin, $yMin), ($xMax, $yMax)]\n";
      }
    }
  }

  return detectionResults;
}


  Map<int, String> classLabels = {
    0: 'Helmet',
    1: 'No Helmet',
    2: 'License Plate',
  };

  void displayDetections(List<Map<String, dynamic>> detections) {
    for (var detection in detections) {
      final className = classLabels[detection['class'] as int];
      print(
        'Detected: $className, '
        'Confidence: ${detection['confidence']}, '
        'Bounding Box: x=${detection['x']}, y=${detection['y']}, '
        'width=${detection['width']}, height=${detection['height']}',
      );
    }
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detection Screen"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.imagePath != null
                  ? Image.file(File(widget.imagePath!))
                  : const Text("No image selected"),
              const SizedBox(height: 20),
              Text(result, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
