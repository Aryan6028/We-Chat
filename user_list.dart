import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';
import 'package:we_chat_app/providers/home_provider.dart';

class UsersList extends StatelessWidget {
  final ScrollController listScrollController;
  final int limit;
  final String textSearch;
  final Widget Function(dynamic document) buildItem;

  const UsersList({
    super.key,
    required this.listScrollController,
    required this.limit,
    required this.textSearch,
    required this.buildItem,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: homeProvider.getStreamFireStore(
        FirestoreConstants.pathUserCollection,
        limit,
        textSearch,
      ),
      builder: (context, snapshot) {
        // 🔴 LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔴 ERROR
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // 🔴 NO DATA (IMPORTANT FIX)
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        // ✅ DATA FOUND
        return ListView.builder(
          controller: listScrollController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return buildItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }
}