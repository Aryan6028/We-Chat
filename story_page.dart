import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/providers/auth_provider.dart';
import 'package:we_chat_app/widgets/loading_view.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class StoryPage extends StatefulWidget {
  const StoryPage({super.key});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  File? _imageFile;
  final picker = ImagePicker();
  bool _isLoading = false;
  String? _userId;

  AuthProvider get _authProvider => context.read<AuthProvider>();

  @override
  void initState() {
    super.initState();
    _userId = _authProvider.userFirebaseId;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadStory() async {
    if (_imageFile == null) {
      Fluttertoast.showToast(
        msg: "Please select an image first!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_userId == null || _userId!.isEmpty) {
      Fluttertoast.showToast(
        msg: "User not logged in!",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeUserId = _userId!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'stories/$safeUserId/$timestamp.jpg';

      final storage = firebase_storage.FirebaseStorage.instance;
      final storageRef = storage.ref().child(fileName);

      final metadata = firebase_storage.SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
      );

      final uploadTask = storageRef.putFile(_imageFile!, metadata);

      final taskSnapshot = await uploadTask;

      if (taskSnapshot.state == firebase_storage.TaskState.success) {
        final imageUrl = await storageRef.getDownloadURL();

        if (imageUrl.isEmpty) {
          throw Exception('Failed to get download URL');
        }

        await FirebaseFirestore.instance.collection('stories').add({
          'userId': _userId,
          'imageUrl': imageUrl,
          'timestamp': timestamp,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Fluttertoast.showToast(
            msg: "Story uploaded successfully!",
            backgroundColor: ColorConstants.buttonSuccess,
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }
    } on firebase_storage.FirebaseException catch (e) {
      String errorMessage = 'Upload failed: ';
      if (e.code == 'object-not-found') {
        errorMessage += 'Storage path not found. Check storage rules.';
      } else if (e.code == 'unauthorized') {
        errorMessage += 'Permission denied. Check storage rules.';
      } else if (e.code == 'canceled') {
        errorMessage += 'Upload was canceled.';
      } else {
        errorMessage += e.message ?? e.code;
      }
      if (mounted) {
        Fluttertoast.showToast(msg: errorMessage, backgroundColor: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: "Error: ${e.toString()}", backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorConstants.gradientStart,
              ColorConstants.gradientEnd,
              ColorConstants.accentPink,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // AppBar
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorConstants.gradientStart,
                          ColorConstants.gradientEnd,
                        ],
                      ),
                    ),
                    child: AppBar(
                      title: const Text(
                        "Add Story",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Body
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Image Preview
                              Container(
                                height: 300,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: _imageFile == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 80,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "No image selected",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 30),
                              // Buttons
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library),
                                label: const Text("Choose from Gallery"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text("Take a Photo"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _uploadStory,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.cloud_upload),
                                label: Text(_isLoading ? "Uploading..." : "Upload Story"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black38,
                    child: const Center(child: LoadingView()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
