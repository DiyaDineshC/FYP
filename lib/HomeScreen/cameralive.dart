import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';


class YoloVideo extends StatefulWidget {
  const YoloVideo({Key? key}) : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;

  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  double confidenceThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    init();
  }

    Future<void> init() async {
  try {
    print("Initializing camera...");
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception("No cameras found");
    }

    print("Camera found: ${cameras[0].toString()}");
    vision = FlutterVision();
    controller = CameraController(cameras[0], ResolutionPreset.low);  // Using low resolution for performance
    await controller.initialize();
    await loadYoloModel();

    setState(() {
      isLoaded = true;
      isDetecting = false;
      yoloResults = [];
    });
    print("Camera and model initialization completed.");
  } catch (e) {
    print("Error during initialization: $e");
    setState(() {
      isLoaded = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    print("Is model loaded: $isLoaded");
    final Size size = MediaQuery.of(context).size;

    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
          Positioned(
            bottom: 75,
            width: MediaQuery.of(context).size.width,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 5,
                  color: Colors.white,
                  style: BorderStyle.solid,
                ),
              ),
              child: isDetecting
                  ? IconButton(
                      onPressed: () async {
                        await stopDetection();
                      },
                      icon: const Icon(
                        Icons.stop,
                        color: Colors.red,
                      ),
                      iconSize: 50,
                    )
                  : IconButton(
                      onPressed: () async {
                        await startDetection();
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 50,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadYoloModel() async {
  try {
    await vision.loadYoloModel(
      labels: 'assets/classes.txt',
      modelPath: 'assets/best_float32.tflite',
      modelVersion: "yolov8",
      numThreads: 2,
      useGpu: true,
    );
    setState(() {
      isLoaded = true;
    });
  } catch (e) {
    print("Error loading YOLO model: $e");
    setState(() {
      isLoaded = false;
    });
  }
}


  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        await yoloOnFrame(image);
      }
    });
  }

    Future<void> stopDetection() async {
    await controller.stopImageStream();
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }


  Future<void> yoloOnFrame(CameraImage cameraImage) async {
  final result = await vision.yoloOnFrame(
    bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
    imageHeight: cameraImage.height,
    imageWidth: cameraImage.width,
    iouThreshold: 0.4,
    confThreshold: 0.4,
    classThreshold: 0.5,
  );
  if (result.isNotEmpty) {
    setState(() {
      yoloResults = result;
    });
  }
  // Explicitly dispose of the camera image to free up memory
  cameraImage.planes.forEach((plane) {
    plane.bytes.clear();
  });
}


  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    return yoloResults.map((result) {
      double objectX = result["box"][0] * factorX;
      double objectY = result["box"][1] * factorY;
      double objectWidth = (result["box"][2] - result["box"][0]) * factorX;
      double objectHeight = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: objectX,
        top: objectY,
        width: objectWidth,
        height: objectHeight,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(2)}%",
            style: const TextStyle(
              backgroundColor: Colors.white,
              fontSize: 14.0,
              color: Colors.black,
            ),
          ),
        ),
      );
    }).toList();
  }

  

  @override
  void dispose() {
    controller.dispose();
    vision.closeYoloModel();
    super.dispose();
  }
}