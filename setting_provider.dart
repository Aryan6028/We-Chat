import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  SettingProvider({
    required this.prefs,
    required this.firebaseFirestore,
    required this.firebaseStorage,
  });

  String? getPref(String key) {
    return prefs.getString(key);
  }

  Future<bool> setPref(String key, String value) async {
    return await prefs.setString(key, value);
  }

  UploadTask uploadFile(File image, String fileName) {
    try {
      // Clean the file name to avoid invalid characters in path
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._/-]'), '_');
      final reference = firebaseStorage.ref().child(cleanFileName);
      
      // Use putFile with metadata for better error handling
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
      );
      
      final uploadTask = reference.putFile(image, metadata);
    return uploadTask;
    } catch (e) {
      // If there's an error creating the reference, rethrow it
      throw Exception('Failed to create storage reference: $e');
    }
  }

  Future<void> updateDataFirestore(
    String collectionPath,
    String path,
    Map<String, String> dataNeedUpdate,
  ) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(path)
        .update(dataNeedUpdate);
  }
}
