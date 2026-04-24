// widgets/users_list.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/providers/home_provider.dart';
import 'package:provider/provider.dart';

class UsersList extends StatelessWidget {
  final ScrollController listScrollController;
  final int limit;
  final String textSearch;
  final Widget Function(DocumentSnapshot?) buildItem;

  const UsersList({
    super.key,
    required this.listScrollController,
    required this.limit,
    required this.textSearch,
    required this.buildItem,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: homeProvider.getStreamFireStore(FirestoreConstants.pathUserCollection, limit, textSearch),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ColorConstants.gradientStart.withOpacity(0.1),
                          ColorConstants.gradientEnd.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 64,
                      color: ColorConstants.gradientStart.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No users found",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start chatting with friends!",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (_, index) => buildItem(docs[index]),
            controller: listScrollController,
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.gradientStart,
              ),
            ),
          );
        }
      },
    );
  }
}
