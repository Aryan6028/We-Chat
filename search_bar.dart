// widgets/search_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/utils/utilities.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Stream<bool> btnClearStream;
  final void Function(String) onChangedDebounced;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.btnClearStream,
    required this.onChangedDebounced,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(colors: [Colors.white, ColorConstants.chatBackground]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        controller: controller,
        onTapOutside: (_) => Utilities.closeKeyboard(),
        onChanged: onChangedDebounced,
        decoration: InputDecoration(
          hintText: 'Search by nickname',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: ColorConstants.gradientStart, size: 22),
          suffixIcon: StreamBuilder<bool>(
            stream: btnClearStream,
            builder: (_, snapshot) {
              return snapshot.data == true
                  ? GestureDetector(
                      onTap: () {
                        controller.clear();
                        
                      },
                      child: Icon(Icons.clear_rounded, color: Colors.grey[600], size: 20),
                    )
                  : const SizedBox.shrink();
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
