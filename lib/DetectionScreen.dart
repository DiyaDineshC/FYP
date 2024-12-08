// import 'dart:io';

// import 'package:flutter/material.dart';

// class DetectionScreen extends StatelessWidget {
//   final String imagePath;
//   final List<dynamic>? predictions; // Adjust type based on your prediction output

//   const DetectionScreen({Key? key, required this.imagePath, this.predictions}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detection Results'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.file(File(imagePath)), // Display the selected image
//             SizedBox(height: 16),
//             Text(
//               'Predictions:',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             predictions != null && predictions!.isNotEmpty
//                 ? Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: predictions!.map((prediction) {
//                       return Text(prediction.toString()); // Display each prediction
//                     }).toList(),
//                   )
//                 : Text('No predictions available.'),
//           ],
//         ),
//       ),
//     );
//   }
// }
