import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:we_chat_app/constants/app_constants.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';
import 'package:we_chat_app/models/user_chat.dart';
import 'package:we_chat_app/providers/setting_provider.dart';
import 'package:we_chat_app/widgets/loading_view.dart' show LoadingView;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _controllerNickname;
  late final TextEditingController _controllerAboutMe;

  String _userId = '';
  String _nickname = '';
  String _aboutMe = '';
  String _avatarUrl = '';

  bool _isLoading = false;
  File? _avatarFile;

  SettingProvider get _settingProvider => context.read<SettingProvider>();

  final _focusNodeNickname = FocusNode();
  final _focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    _readLocal();
  }

  void _readLocal() {
    setState(() {
      _userId = _settingProvider.getPref(FirestoreConstants.id) ?? "";
      _nickname = _settingProvider.getPref(FirestoreConstants.nickname) ?? "";
      _aboutMe = _settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      _avatarUrl = _settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
    });

    _controllerNickname = TextEditingController(text: _nickname);
    _controllerAboutMe = TextEditingController(text: _aboutMe);
  }

  Future<bool> _pickAvatar() async {
    final imagePicker = ImagePicker();
    final pickedXFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
          Fluttertoast.showToast(msg: err.toString());
          return null;
        });
    if (pickedXFile != null) {
      final imageFile = File(pickedXFile.path);
      setState(() {
        _avatarFile = imageFile;
        _isLoading = true;
      });
      return true;
    } else {
      return false;
    }
  }

  Future<void> _uploadFile() async {
    final fileName = _userId;
    final uploadTask = _settingProvider.uploadFile(_avatarFile!, fileName);
    try {
      final snapshot = await uploadTask;
      _avatarUrl = await snapshot.ref.getDownloadURL();
      final updateInfo = UserChat(
        id: _userId,
        photoUrl: _avatarUrl,
        nickname: _nickname,
        aboutMe: _aboutMe,
      );
      _settingProvider
          .updateDataFirestore(
            FirestoreConstants.pathUserCollection,
            _userId,
            updateInfo.toJson(),
          )
          .then((_) async {
            await _settingProvider.setPref(
              FirestoreConstants.photoUrl,
              _avatarUrl,
            );
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(msg: "Upload success");
          })
          .catchError((err) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(msg: err.toString());
          });
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void _handleUpdateData() {
    _focusNodeNickname.unfocus();
    _focusNodeAboutMe.unfocus();

    setState(() {
      _isLoading = true;
    });
    UserChat updateInfo = UserChat(
      id: _userId,
      photoUrl: _avatarUrl,
      nickname: _nickname,
      aboutMe: _aboutMe,
    );
    _settingProvider
        .updateDataFirestore(
          FirestoreConstants.pathUserCollection,
          _userId,
          updateInfo.toJson(),
        )
        .then((_) async {
          await _settingProvider.setPref(
            FirestoreConstants.nickname,
            _nickname,
          );
          await _settingProvider.setPref(FirestoreConstants.aboutMe, _aboutMe);
          await _settingProvider.setPref(
            FirestoreConstants.photoUrl,
            _avatarUrl,
          );

          setState(() {
            _isLoading = false;
          });

          Fluttertoast.showToast(msg: "Update success");
        })
        .catchError((err) {
          setState(() {
            _isLoading = false;
          });

          Fluttertoast.showToast(msg: err.toString());
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              ColorConstants.chatBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Colorful AppBar
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstants.gradientStart,
                      ColorConstants.gradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.gradientStart.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: AppBar(
        title: Text(
          AppConstants.settingsTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
        ),
        centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
      ),
              Expanded(
                child: Stack(
        children: [
          SingleChildScrollView(
                      padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                          // Avatar Section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                    _pickAvatar().then((isSuccess) {
                      if (isSuccess) _uploadFile();
                    });
                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              ColorConstants.gradientStart,
                                              ColorConstants.gradientEnd,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: ColorConstants.gradientStart.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(4),
                    child: _avatarFile == null
                        ? _avatarUrl.isNotEmpty
                                                ? ClipOval(
                                  child: Image.network(
                                    _avatarUrl,
                                    fit: BoxFit.cover,
                                                      width: 100,
                                                      height: 100,
                                    errorBuilder: (_, __, ___) {
                                                        return Container(
                                                          width: 100,
                                                          height: 100,
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                ColorConstants.gradientStart,
                                                                ColorConstants.gradientEnd,
                                                              ],
                                                            ),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 50,
                                                            color: Colors.white,
                                                          ),
                                      );
                                    },
                                    loadingBuilder: (_, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                                          width: 100,
                                                          height: 100,
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                ColorConstants.gradientStart,
                                                                ColorConstants.gradientEnd,
                                                              ],
                                                            ),
                                                            shape: BoxShape.circle,
                                                          ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                                              color: Colors.white,
                                                              value: loadingProgress.expectedTotalBytes != null
                                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                                        loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                                                : Container(
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          ColorConstants.gradientStart,
                                                          ColorConstants.gradientEnd,
                                                        ],
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 50,
                                                      color: Colors.white,
                                                    ),
                                )
                        : ClipOval(
                            child: Image.file(
                              _avatarFile!,
                                                  width: 100,
                                                  height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: ColorConstants.buttonSuccess,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tap to change profile photo',
                        style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),

                          // Input Fields
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                      ),
                              ],
                            ),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nickname',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.gradientStart,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                          decoration: InputDecoration(
                                    hintText: 'Enter your nickname',
                                    prefixIcon: Icon(Icons.person, color: ColorConstants.gradientStart),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: ColorConstants.gradientStart, width: 2),
                            ),
                          ),
                          controller: _controllerNickname,
                          onChanged: (value) {
                            _nickname = value;
                          },
                          focusNode: _focusNodeNickname,
                        ),
                                SizedBox(height: 24),
                                Text(
                        'About me',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                                    color: ColorConstants.gradientStart,
                                    fontSize: 16,
                        ),
                      ),
                                SizedBox(height: 12),
                                TextField(
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Tell us about yourself...',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(bottom: 60),
                                      child: Icon(Icons.info_outline, color: ColorConstants.gradientStart),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: ColorConstants.gradientStart, width: 2),
                            ),
                          ),
                          controller: _controllerAboutMe,
                          onChanged: (value) {
                            _aboutMe = value;
                          },
                          focusNode: _focusNodeAboutMe,
                        ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                          // Update Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorConstants.gradientStart,
                                  ColorConstants.gradientEnd,
                                ],
                ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConstants.gradientStart.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                    onPressed: _handleUpdateData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                    child: Text(
                                'Update Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                    ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                    // Loading
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black38,
                          child: Center(child: LoadingView()),
                    ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerNickname.dispose();
    _controllerAboutMe.dispose();
    _focusNodeNickname.dispose();
    _focusNodeAboutMe.dispose();
    super.dispose();
  }
}


