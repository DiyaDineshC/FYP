import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionResultScreen extends StatelessWidget {
  final String imageIdentifier; // Unique identifier for the image
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DetectionResultScreen({required this.imageIdentifier}); // Accepts the identifier as a parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detection Results')),
      body: StreamBuilder(
        stream: _firestore
            .collection('Boundingboxes') // Your collection name
            .where('image_identifier', isEqualTo: imageIdentifier)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No detections found.'));
          }

          var doc = snapshot.data!.docs[0];
          String? imageUrl = doc['image_url']; // Use image_url as the output image URL

          // Check for null or empty URL
          if (imageUrl == null || imageUrl.isEmpty) {
            return Center(child: Text('No image URL found.'));
          }

          // Display the processed image (image with bounding boxes)
          return Center(
            child: Image.network(imageUrl),  // Fetch and display the processed image with bounding boxes
          );
        },
      ),
    );
  }
}
