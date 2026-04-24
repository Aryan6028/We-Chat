import 'package:flutter/material.dart';
import 'package:we_chat_app/constants/app_constants.dart';
import 'package:we_chat_app/constants/color_constants.dart';

class FullPhotoPage extends StatelessWidget {
  final String url;

  const FullPhotoPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.fullPhotoTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
     
      body: Container(
        child: InteractiveViewer(
          child: Center(
            child: Image.network(
              url,
              fit: BoxFit.contain,
            ),
          ),
        ),
     ) );
  }
}