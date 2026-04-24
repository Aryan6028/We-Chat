import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';
import 'package:we_chat_app/models/user_chat.dart';

enum Status {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateException,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  AuthProvider({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.prefs,
    required this.firebaseFirestore,
  });

  Status _status = Status.uninitialized;

  Status get status => _status;

  String? get userFirebaseId => prefs.getString(FirestoreConstants.id);

  Future<bool> isLoggedIn() async {
    // In google_sign_in 7.x, check login status via SharedPreferences
    return prefs.getString(FirestoreConstants.id)?.isNotEmpty == true;
  }

  Future<bool> handleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();

    try {
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      // Get access token through authorization client
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);
      final credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebaseUser = (await firebaseAuth.signInWithCredential(
        credential,
      )).user;
      if (firebaseUser == null) {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }

      final result = await firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
          .get();
      final documents = result.docs;
      if (documents.isEmpty) {
        // Writing data to server because here is a new user
        firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(firebaseUser.uid)
            .set({
              FirestoreConstants.nickname: firebaseUser.displayName,
              FirestoreConstants.photoUrl: firebaseUser.photoURL,
              FirestoreConstants.id: firebaseUser.uid,
              FirestoreConstants.createdAt: DateTime.now()
                  .millisecondsSinceEpoch
                  .toString(),
              FirestoreConstants.chattingWith: null,
            });

        // Write data to local storage
        User? currentUser = firebaseUser;
        await prefs.setString(FirestoreConstants.id, currentUser.uid);
        await prefs.setString(
          FirestoreConstants.nickname,
          currentUser.displayName ?? "",
        );
        await prefs.setString(
          FirestoreConstants.photoUrl,
          currentUser.photoURL ?? "",
        );
      } else {
        // Already sign up, just get data from firestore
        final documentSnapshot = documents.first;
        final userChat = UserChat.fromDocument(documentSnapshot);
        // Write data to local
        await prefs.setString(FirestoreConstants.id, userChat.id);
        await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
        await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
        await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
      }
      _status = Status.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.authenticateCanceled;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _status = Status.authenticating;
    notifyListeners();

    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }

      final result = await firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
          .get();

      final documents = result.docs;
      if (documents.isNotEmpty) {
        final documentSnapshot = documents.first;
        final userChat = UserChat.fromDocument(documentSnapshot);
        // Write data to local
        await prefs.setString(FirestoreConstants.id, userChat.id);
        await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
        await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
        await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
      } else {
        // User exists in Firebase Auth but not in Firestore, create document
        firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(firebaseUser.uid)
            .set({
              FirestoreConstants.nickname:
                  firebaseUser.displayName ??
                  firebaseUser.email?.split('@')[0] ??
                  "User",
              FirestoreConstants.photoUrl: firebaseUser.photoURL ?? "",
              FirestoreConstants.id: firebaseUser.uid,
              FirestoreConstants.createdAt: DateTime.now()
                  .millisecondsSinceEpoch
                  .toString(),
              FirestoreConstants.chattingWith: null,
              FirestoreConstants.aboutMe: "",
            });

        await prefs.setString(FirestoreConstants.id, firebaseUser.uid);
        await prefs.setString(
          FirestoreConstants.nickname,
          firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              "User",
        );
        await prefs.setString(
          FirestoreConstants.photoUrl,
          firebaseUser.photoURL ?? "",
        );
        await prefs.setString(FirestoreConstants.aboutMe, "");
      }

      _status = Status.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.authenticateError;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _status = Status.authenticating;
    notifyListeners();

    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }

      // Update display name to email username
      final displayName = email.split('@')[0];
      await firebaseUser.updateProfile(displayName: displayName);

      // Writing data to server because here is a new user
      firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .doc(firebaseUser.uid)
          .set({
            FirestoreConstants.nickname: displayName,
            FirestoreConstants.photoUrl: firebaseUser.photoURL ?? "",
            FirestoreConstants.id: firebaseUser.uid,
            FirestoreConstants.createdAt: DateTime.now().millisecondsSinceEpoch
                .toString(),
            FirestoreConstants.chattingWith: null,
            FirestoreConstants.aboutMe: "",
          });

      // Write data to local storage
      await prefs.setString(FirestoreConstants.id, firebaseUser.uid);
      await prefs.setString(FirestoreConstants.nickname, displayName);
      await prefs.setString(
        FirestoreConstants.photoUrl,
        firebaseUser.photoURL ?? "",
      );
      await prefs.setString(FirestoreConstants.aboutMe, "");

      _status = Status.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.authenticateError;
      notifyListeners();
      return false;
    }
  }

  void handleException() {
    _status = Status.authenticateException;
    notifyListeners();
  }

  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
