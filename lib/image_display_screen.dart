// // image_display_screen.dart
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'tflite_model.dart';

// class ImageDisplayScreen extends StatelessWidget {
//   final String imagePath;
//   final TFLiteModel _model = TFLiteModel();

//   ImageDisplayScreen({required this.imagePath});

//   @override
//   Widget build(BuildContext context) {
//     final File image = File(imagePath);
//     final List<Map<String, dynamic>> results = _model.predict(image);

//     return Scaffold(
//       appBar: AppBar(title: Text("Helmet Detection Results")),
//       body: Column(
//         children: [
//           Image.file(image),
//           Expanded(
//             child: ListView.builder(
//               itemCount: results.length,
//               itemBuilder: (context, index) {
//                 final rec = results[index];
//                 return ListTile(
//                   title: Text("${rec["label"]}: ${(rec["confidence"] * 100).toStringAsFixed(2)}%"),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
