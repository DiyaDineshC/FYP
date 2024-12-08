// // home_screen.dart
// import 'package:flutter/material.dart';
// import 'detect_screen.dart';
// import 'image_display_screen.dart';
// import 'package:image_picker/image_picker.dart';
// // import 'dart:io';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final ImagePicker _picker = ImagePicker();
  
//   void _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ImageDisplayScreen(imagePath: pickedFile.path),
//         ),
//       );
//     }
//   }

//   void _openCamera() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => DetectScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Helmet Detection')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             ElevatedButton(
//               onPressed: _pickImage,
//               child: Text('Select Image from Gallery'),
//             ),
//             ElevatedButton(
//               onPressed: _openCamera,
//               child: Text('Open Camera for Real-time Detection'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
