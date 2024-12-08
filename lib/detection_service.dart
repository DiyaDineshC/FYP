import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// Function to preprocess the image for the model
List<List<List<List<double>>>> preprocessImage(File imageFile) {
  final rawImage = img.decodeImage(imageFile.readAsBytesSync())!;

  // Resize the image to 640x640 as expected by the YOLOv8 model
  final resizedImage = img.copyResize(rawImage, width: 640, height: 640);

  // Prepare the input as [1, 640, 640, 3] with normalized RGB values
  List<List<List<List<double>>>> input = List.generate(
    1,
    (_) => List.generate(
      640,
      (_) => List.generate(
        640,
        (_) => List.generate(3, (_) => 0.0),
      ),
    ),
  );

  // Populate input with normalized RGB values
  for (int x = 0; x < 640; x++) {
    for (int y = 0; y < 640; y++) {
      final pixel = resizedImage.getPixel(x, y);
      input[0][x][y][0] = img.getRed(pixel) / 255.0;   // R
      input[0][x][y][1] = img.getGreen(pixel) / 255.0; // G
      input[0][x][y][2] = img.getBlue(pixel) / 255.0;  // B
    }
  }
  return input;
}

// Function to run the TensorFlow Lite model
Future<List> runModel(List<List<List<List<double>>>> input) async {
  final interpreter = await Interpreter.fromAsset("assets/best_float32.tflite");

  // Prepare output buffer for YOLOv8 model
  var output = List.generate(1, (_) => List.generate(7, (_) => List.filled(8400, 0.0)));

  // Run inference
  interpreter.run(input, output);
  interpreter.close();
  return output;
}

// Function to parse the output from the model
List<Map<String, dynamic>> parseOutput(List output, double threshold) {
  List<Map<String, dynamic>> detections = [];

  for (int i = 0; i < 8400; i++) {
    double confidence = output[0][4][i];
    if (confidence > threshold) {
      Map<String, dynamic> detection = {
        'x': output[0][0][i],
        'y': output[0][1][i],
        'width': output[0][2][i],
        'height': output[0][3][i],
        'confidence': confidence,
        'class': output[0][5][i],
      };
      detections.add(detection);
    }
  }
  return detections;
}

// Function to display detections
void displayDetections(List<Map<String, dynamic>> detections) {
  Map<int, String> classLabels = {
    0: 'Helmet',
    1: 'No Helmet',
    2: 'License Plate',
  };

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

// Example class to integrate the detection functionality
class DetectionService {
  final String imagePath;

  DetectionService(this.imagePath);

  Future<void> performDetection() async {
    // Step 1: Preprocess the image
    var input = preprocessImage(File(imagePath));

    // Step 2: Run the model
    var output = await runModel(input);

    // Step 3: Parse the output
    var detections = parseOutput(output, 0.5); // Adjust threshold as needed

    // Step 4: Display detections
    displayDetections(detections);
  }
}
