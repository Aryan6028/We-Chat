import 'package:flutter/material.dart';
import 'package:we_chat_app/constants/color_constants.dart';

class ChatAppBar extends StatelessWidget {
  final String title;
  final bool selectionMode;
  final int selectedCount;
  final VoidCallback onBack;
  final VoidCallback onCancelSelection;
  final Future<void> Function() onDeleteSelected;
  final Future<void> Function() onDeleteChat;

  const ChatAppBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onDeleteSelected,
    required this.onDeleteChat,
    required this.onCancelSelection,
    this.selectionMode = false,
    this.selectedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorConstants.gradientStart, ColorConstants.gradientEnd],
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
          selectionMode ? "$selectedCount selected" : title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
        actions: selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete selected',
                  onPressed: () => onDeleteSelected(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel selection',
                  onPressed: onCancelSelection,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Delete chat',
                  onPressed: () => onDeleteChat(),
                ),
              ],
      ),
    );
  }
}
