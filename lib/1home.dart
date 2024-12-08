import 'dart:developer';
import 'dart:io'; // Import dart:io for File handling
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:helmet_license/1detect_screen.dart';
import 'package:helmet_license/1models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<CameraDescription> cameras;
  Interpreter? interpreter;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    await setupCameras();
  }

   loadModel(String model) async {
    try {
      switch (model) {
        case yolo:
          interpreter = await Interpreter.fromAsset("assets/best_float32.tflite");
          break;

        // case mobilenet:
        //   interpreter = await Interpreter.fromAsset("assets/mobilenet_v1_1.0_224.tflite");
        //   break;

        // case posenet:
        //   interpreter = await Interpreter.fromAsset("assets/posenet_mv1_075_float_from_checkpoints.tflite");
        //   break;

        // default:
        //   interpreter = await Interpreter.fromAsset("assets/ssd_mobilenet.tflite");
      }
      log("Model loaded: $model");
    } catch (e) {
      log("Failed to load model: $e");
    }
  }

void onSelect(String model) {
  if (model == 'Tiny Yolov2') {
    selectImageFromGallery();  // Open gallery when TINY YOLOv2 is selected
  } else {
    loadModel(model);
    final route = MaterialPageRoute(builder: (context) {
      return DetectScreen(cameras: cameras, model: model);
    });
    Navigator.of(context).push(route);
  }
}


 setupCameras() async {
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    log('Error: ${e.code}\nError Message: ${e.description}');
  }
}



Future<void> selectImageFromGallery() async {
  log('Opening gallery...');
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    File imageFile = File(image.path);
    log('Image selected: ${imageFile.path}');
    final route = MaterialPageRoute(builder: (context) {
      return DetectScreen(
        imagePath: imageFile.path,
        model: 'Tiny Yolov2',
        cameras: cameras,
      );
    });
    Navigator.of(context).push(route);
  } else {
    log('No image selected');
  }
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            
            ElevatedButton(
  child: const Text('YOLOv8'),
  onPressed: () => onSelect('Tiny Yolov2'),  // Trigger the TINY YOLOv2 logic
),

            
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    interpreter?.close(); // Close the interpreter when the widget is disposed
    super.dispose();
  }
}
