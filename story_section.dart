import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';

class StorySection extends StatelessWidget {
  final VoidCallback onNavigateToStory;

  const StorySection({super.key, required this.onNavigateToStory});

  void _openStoryViewer(
    BuildContext context,
    String imageUrl,
    String nickname,
  ) {
    if (imageUrl.isEmpty) {
      Fluttertoast.showToast(
        msg: "No story image available",
        backgroundColor: Colors.grey,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 200,
                        width: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    nickname,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYourStoryTile() {
    return GestureDetector(
      onTap: onNavigateToStory,
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.gradientStart,
                  ColorConstants.gradientEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(32.5),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.gradientStart.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Your Story',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      [ColorConstants.gradientStart, ColorConstants.gradientEnd],
      [ColorConstants.accentPink, ColorConstants.accentOrange],
      [ColorConstants.gradientBlue, ColorConstants.gradientPurple],
      [ColorConstants.accentYellow, ColorConstants.accentOrange],
      [ColorConstants.gradientEnd, ColorConstants.accentPink],
    ];

    final storiesStream = FirebaseFirestore.instance
        .collection('stories')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      child: StreamBuilder<QuerySnapshot>(
        stream: storiesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // Show only "Your Story" button when loading, no fake stories
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildYourStoryTile(),
              ],
            );
          }

          final docs = snapshot.data!.docs;
          final Map<String, QueryDocumentSnapshot> latestByUser = {};
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final userId = (data['userId'] ?? '').toString();
            if (userId.isEmpty) continue;
            if (!latestByUser.containsKey(userId)) latestByUser[userId] = d;
          }

          final storyDocs = latestByUser.values.toList();

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildYourStoryTile(),
              const SizedBox(width: 10),
              ...storyDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final userId = (data['userId'] ?? '').toString();
                final imageUrl = (data['imageUrl'] ?? '').toString();
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(FirestoreConstants.pathUserCollection)
                      .doc(userId)
                      .get(),
                  builder: (context, userSnap) {
                    String nickname = 'User';
                    String photoUrl = '';
                    if (userSnap.hasData && userSnap.data!.exists) {
                      final ud = userSnap.data!.data() as Map<String, dynamic>;
                      nickname = (ud[FirestoreConstants.nickname] ?? nickname)
                          .toString();
                      photoUrl = (ud[FirestoreConstants.photoUrl] ?? '')
                          .toString();
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _openStoryViewer(context, imageUrl, nickname),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      gradientColors[(userId.hashCode.abs()) %
                                          gradientColors.length],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        gradientColors[(userId.hashCode.abs()) %
                                                gradientColors.length][0]
                                            .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 27,
                                  backgroundImage: imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : (photoUrl.isNotEmpty
                                            ? NetworkImage(photoUrl)
                                            : null),
                                  child: (imageUrl.isEmpty && photoUrl.isEmpty)
                                      ? const Icon(Icons.person, size: 30)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 70,
                            child: Text(
                              nickname,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
