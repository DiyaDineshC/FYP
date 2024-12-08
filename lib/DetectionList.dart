import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DetectionList extends StatelessWidget {
  final String imageIdentifier; // Unique identifier for the specific image
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Constructor to accept the imageIdentifier
  DetectionList({required this.imageIdentifier});

  // Method to upload an image and get the image URL as a unique identifier
  Future<String> uploadImageAndGetIdentifier() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      throw Exception('No image selected');
    }

    // Create a reference to Firebase Storage
    File imageFile = File(pickedFile.path);
    String fileName = pickedFile.name;
    Reference storageReference = FirebaseStorage.instance.ref().child('uploads/$fileName');

    // Upload the image to Firebase Storage
    await storageReference.putFile(imageFile);

    // Get the image URL (which will act as a unique identifier)
    String imageUrl = await storageReference.getDownloadURL();

    return imageUrl;
  }

  // Method to get the image identifier from Firestore
  Future<String> getImageIdentifierFromFirestore() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Images')
        .limit(1) // You can adjust this to get a specific document
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No image data found');
    }

    DocumentSnapshot doc = snapshot.docs[0];
    return doc['image_identifier'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detection Results')),
      body: StreamBuilder(
        stream: _firestore
            .collection('Boundingboxes')
            .where('image_identifier', isEqualTo: imageIdentifier)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No detections found for this image.'));
          }

          var doc = snapshot.data!.docs[0];
          String imageUrl = doc['image_url'];
          List detections = doc['detections'];

          return FutureBuilder(
            future: _storage.refFromURL(imageUrl).getDownloadURL(),
            builder: (context, AsyncSnapshot<String> imageUrlSnapshot) {
              if (imageUrlSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (imageUrlSnapshot.hasError) {
                return Center(child: Text('Error loading image.'));
              }

              String imageUrl = imageUrlSnapshot.data!;

              return ListView.builder(
                itemCount: detections.length,
                itemBuilder: (context, index) {
                  var detection = detections[index];
                  var label = detection['label'];  // Label of the detected object
                  var rect = detection['rect'];    // Bounding box coordinates
                  var x = rect['x'];
                  var y = rect['y'];
                  var width = rect['w'];
                  var height = rect['h'];

                  return ListTile(
                    contentPadding: EdgeInsets.all(8),
                    title: Text(
                      '$label',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Coordinates: x=$x, y=$y, width=$width, height=$height',
                    ),
                    leading: Image.network(imageUrl, width: 50, height: 50),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
