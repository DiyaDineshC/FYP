import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:helmet_license/1models.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;

typedef Callback = void Function(List<dynamic> list, int h, int w);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final String model;

  const Camera(this.cameras, this.model, this.setRecognitions, {super.key});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  late CameraController controller;
  late Interpreter interpreter; // TensorFlow Lite interpreter
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize camera
    if (widget.cameras.isEmpty) {
      log('No camera is found');
    } else {
      controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        // Load the model
        loadModel();

        // Start image stream
        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;

            int startTime = DateTime.now().millisecondsSinceEpoch;

            // Replace Tflite calls with interpreter calls
            List<dynamic> recognitions = [];

            // Prepare input for the interpreter
            var input = img.planes.map((plane) {
              return plane.bytes;
            }).toList();

            // Check which model to use
            if (widget.model == mobilenet) {
              // Logic for MobileNet model
              recognitions = runModelOnMobileNet(input, img);
            } else if (widget.model == posenet) {
              // Logic for PoseNet model
              recognitions = runModelOnPoseNet(input, img);
            } else {
              // Logic for YOLO or SSD MobileNet model
              recognitions = runObjectDetection(input, img);
            }

            // Measure end time and log detection duration
            int endTime = DateTime.now().millisecondsSinceEpoch;
            log("Detection took ${endTime - startTime} ms");
            widget.setRecognitions(recognitions, img.height, img.width);

            isDetecting = false;
          }
        });
      });
    }
  }

  void loadModel() async {
    // Load your model here
    interpreter = await Interpreter.fromAsset('assets/best_float32.tflite'); // Replace with your model path
  }

  List<dynamic> runModelOnMobileNet(List<List<int>> input, CameraImage img) {
    // Implement MobileNet detection logic here using the interpreter
    // Use the interpreter to make predictions on the input
    // Return the recognitions list
    return []; // Placeholder
  }

  List<dynamic> runModelOnPoseNet(List<List<int>> input, CameraImage img) {
    // Implement PoseNet detection logic here using the interpreter
    // Return the recognitions list
    return []; // Placeholder
  }

  List<dynamic> runObjectDetection(List<List<int>> input, CameraImage img) {
    // Implement Object Detection logic (YOLO or SSD MobileNet) here using the interpreter
    // Return the recognitions list
    return []; // Placeholder
  }

  @override
  void dispose() {
    controller.dispose();
    interpreter.close(); // Close the interpreter
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize!;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
  }
}
