import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stream_auth_firebase/utils/stream_client.dart';

class Authentication {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFunctions functions = FirebaseFunctions.instance;
  static User? firebaseUser;

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  Future<bool> isSignedIn(BuildContext context) async {
    firebaseUser = auth.currentUser;
    bool isSignedIn = false;

    if (firebaseUser != null) {
      isSignedIn = true;
      try {
        final callable = functions.httpsCallable('getStreamUserToken');
        final results = await callable();
        String? token = results.data;

        if (token != null) {
          StreamClient.initialize(token, context);
        }
      } catch (e) {
        print('Error in fetching token: $e');
      }
    }

    return isSignedIn;
  }

  Future<void> signInUsingEmailPassword({
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

      if (token != null) {
        print('Stream token retrieved (signed in)');

        StreamClient.initialize(token, context);
      }
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
  }

  Future<void> registerUsingEmailPassword({
    required String name,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        await firebaseUser!.updateDisplayName(name);
        await firebaseUser!.reload();
        firebaseUser = auth.currentUser;
      } else {
        throw ('Firebase user is null');
      }

      final callable = functions.httpsCallable('createStreamUserAndGetToken');
      final results = await callable();
      String? token = results.data;

      if (token != null) {
        print('Stream token retrieved (registered)');

        StreamClient.initialize(token, context);
      }
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
  }

  Future<void> signOut() async {
    // Revoke Stream user token.
    final callable = functions.httpsCallable('revokeStreamUserToken');
    await callable();
    print('Stream user token revoked');

    // Close connection
    StreamClient.client.closeConnection();

    // Sign out Firebase.
    await auth.signOut();
    print('Firebase signed out');
  }
}
