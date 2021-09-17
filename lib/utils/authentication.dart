import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Authentication {
  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFunctions functions = FirebaseFunctions.instance;
  User? firebaseUser;

  Future<String?> signInUsingEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    String? token;

    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = userCredential.user;
      final callable = functions.httpsCallable('getStreamUserToken');
      final results = await callable();
      token = results.data;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        ScaffoldMessenger.of(context).showSnackBar(
          Authentication.customSnackBar(
            content: 'No user found for that email. Please create an account.',
          ),
        );
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided.');
        ScaffoldMessenger.of(context).showSnackBar(
          Authentication.customSnackBar(
            content: 'Wrong password provided.',
          ),
        );
      }
    }

    return token;
  }

  Future<String?> registerUsingEmailPassword({
    required String name,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    String? token;

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser = userCredential.user;
      await firebaseUser!.updateDisplayName(name);
      await firebaseUser!.reload();
      firebaseUser = auth.currentUser;

      final callable = functions.httpsCallable('createStreamUserAndGetToken');
      final results = await callable();
      token = results.data;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        ScaffoldMessenger.of(context).showSnackBar(
          Authentication.customSnackBar(
            content: 'The password provided is too weak.',
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        ScaffoldMessenger.of(context).showSnackBar(
          Authentication.customSnackBar(
            content: 'The account already exists for that email.',
          ),
        );
      }
    } catch (e) {
      print(e);
    }

    return token;
  }

  Future<void> signOut() async {
    // Revoke Stream user token.
    final callable = functions.httpsCallable('revokeStreamUserToken');
    await callable();
    print('Stream user token revoked');

    // Sign out Firebase.
    await auth.signOut();
    print('Firebase signed out');
  }
}
