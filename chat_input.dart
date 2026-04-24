import 'package:flutter/material.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/constants/type_message.dart';

typedef PickImageCallback = Future<bool> Function();
typedef UploadFileCallback = Future<void> Function();
typedef SendMessageCallback = void Function(String content, int type);

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final PickImageCallback onPickImage;
  final VoidCallback onGetSticker;
  final UploadFileCallback onUploadFile;
  final SendMessageCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onPickImage,
    required this.onGetSticker,
    required this.onUploadFile,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.chatBackground,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.image, color: ColorConstants.gradientStart),
                  onPressed: () {
                    onPickImage().then((isSuccess) {
                      if (isSuccess) onUploadFile();
                    });
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.chatBackground,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.face, color: ColorConstants.gradientStart),
                  onPressed: onGetSticker,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorConstants.chatBackground,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    onTapOutside: (_) {},
                    onSubmitted: (_) {
                      onSend(controller.text, TypeMessage.text);
                    },
                    style: TextStyle(color: Colors.grey[800], fontSize: 15),
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    focusNode: focusNode,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
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
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: () => onSend(controller.text, TypeMessage.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
