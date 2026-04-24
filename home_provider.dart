import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';

class HomeProvider {
  final FirebaseFirestore firebaseFirestore;

  HomeProvider({required this.firebaseFirestore});

  Future<void> updateDataFirestore(
    String collectionPath,
    String path,
    Map<String, dynamic> dataNeedUpdate,
  ) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(path)
        .update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getStreamFireStore(
    String pathCollection,
    int limit,
    String? textSearch,
  ) {
    // 🔥 FIX: Always use orderBy (IMPORTANT)
    if (textSearch != null && textSearch.isNotEmpty) {
      return firebaseFirestore
          .collection(pathCollection)
          .orderBy(FirestoreConstants.nickname)
          .startAt([textSearch])
          .endAt([textSearch + '\uf8ff'])
          .limit(limit)
          .snapshots();
    } else {
      return firebaseFirestore
          .collection(pathCollection)
          .orderBy(FirestoreConstants.nickname)
          .limit(limit)
          .snapshots();
    }
  }
}