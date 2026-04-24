import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:we_chat_app/constants/firestore_constants.dart';
import 'package:we_chat_app/constants/type_message.dart';
import 'package:we_chat_app/models/message_chat.dart';

class ChatProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider({
    required this.firebaseFirestore,
    required this.prefs,
    required this.firebaseStorage,
  });

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(
    String collectionPath,
    String docPath,
    Map<String, dynamic> dataNeedUpdate,
  ) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(docPath)
        .update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  void sendMessage(
    String content,
    int type,
    String groupChatId,
    String currentUserId,
    String peerId,
  ) {
    final documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    final messageChat = MessageChat(
      idFrom: currentUserId,
      idTo: peerId,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
    );

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(documentReference, messageChat.toJson());
    });
  }

  /// Add sample chat data between two users for testing/demonstration
  Future<void> addSampleChatData(String userId1, String userId2) async {
    // Determine groupChatId (consistent ordering)
    String groupChatId;
    if (userId1.compareTo(userId2) > 0) {
      groupChatId = '$userId1-$userId2';
    } else {
      groupChatId = '$userId2-$userId1';
    }

    // Sample messages in Hindi and English
    final sampleMessages = [
      {
        'from': userId1,
        'to': userId2,
        'content': 'Namaste! Kaise ho?',
        'delay': 0,
      },
      {
        'from': userId2,
        'to': userId1,
        'content': 'Main theek hoon, aap kaise ho?',
        'delay': 2000,
      },
      {
        'from': userId1,
        'to': userId2,
        'content': 'Main bhi theek hoon. Kya kar rahe ho?',
        'delay': 4000,
      },
      {
        'from': userId2,
        'to': userId1,
        'content': 'Bas kaam kar raha hoon. Aap?',
        'delay': 6000,
      },
      {
        'from': userId1,
        'to': userId2,
        'content': 'Maine abhi Flutter app banaya hai!',
        'delay': 8000,
      },
      {
        'from': userId2,
        'to': userId1,
        'content': 'Wah! Kaafi achha hai. Mujhe bhi sikha do 😊',
        'delay': 10000,
      },
      {
        'from': userId1,
        'to': userId2,
        'content': 'Bilkul! Kabhi milte hain to discuss karte hain.',
        'delay': 12000,
      },
      {
        'from': userId2,
        'to': userId1,
        'content': 'Great! Weekend pe plan banate hain.',
        'delay': 14000,
      },
      {
        'from': userId1,
        'to': userId2,
        'content': 'Perfect! Phir milte hain. 👍',
        'delay': 16000,
      },
    ];

    final baseTime = DateTime.now().subtract(Duration(minutes: 30));

    for (var msg in sampleMessages) {
      final timestamp = baseTime.add(
        Duration(milliseconds: msg['delay'] as int),
      );
      final documentReference = firebaseFirestore
          .collection(FirestoreConstants.pathMessageCollection)
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(timestamp.millisecondsSinceEpoch.toString());

      final messageChat = MessageChat(
        idFrom: msg['from'] as String,
        idTo: msg['to'] as String,
        timestamp: timestamp.millisecondsSinceEpoch.toString(),
        content: msg['content'] as String,
        type: TypeMessage.text,
      );

      await firebaseFirestore.runTransaction((transaction) async {
        transaction.set(documentReference, messageChat.toJson());
      });

      // Small delay to avoid rate limiting
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<void> deleteChatHistory(String userId1, String userId2) async {
    if (userId1.isEmpty || userId2.isEmpty)
      throw Exception('User ids must be provided');

    // Determine groupChatId (consistent ordering)
    String groupChatId;
    if (userId1.compareTo(userId2) > 0) {
      groupChatId = '$userId1-$userId2';
    } else {
      groupChatId = '$userId2-$userId1';
    }

    final collectionRef = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId);

    // Get all documents (may need pagination for very large chats)
    QuerySnapshot snapshot = await collectionRef.get();
    if (snapshot.docs.isEmpty) return;

    // Delete in batches of up to 500
    const batchSize = 500;
    List<DocumentSnapshot> docs = snapshot.docs;
    int index = 0;
    while (index < docs.length) {
      final batch = firebaseFirestore.batch();
      final end = (index + batchSize) > docs.length
          ? docs.length
          : index + batchSize;
      for (int i = index; i < end; i++) {
        batch.delete(docs[i].reference);
      }
      await batch.commit();
      index = end;
    }
  }

  Future<void> deleteMessage(String groupChatId, String messageId) async {
    if (groupChatId.isEmpty || messageId.isEmpty) return;

    final docRef = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(messageId);

    await docRef.delete();
  }

  Future<void> deleteMessages(
    String groupChatId,
    List<String> messageIds,
  ) async {
    if (groupChatId.isEmpty || messageIds.isEmpty) return;

    const batchSize = 500;
    int index = 0;
    while (index < messageIds.length) {
      final batch = firebaseFirestore.batch();
      final end = (index + batchSize) > messageIds.length
          ? messageIds.length
          : index + batchSize;
      for (int i = index; i < end; i++) {
        final docRef = firebaseFirestore
            .collection(FirestoreConstants.pathMessageCollection)
            .doc(groupChatId)
            .collection(groupChatId)
            .doc(messageIds[i]);
        batch.delete(docRef);
      }
      await batch.commit();
      index = end;
    }
  }
}
