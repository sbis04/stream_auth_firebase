import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stream_auth_firebase/screens/channel_list_page.dart';
import 'package:stream_auth_firebase/secrets.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as sc;

class Authentication {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFunctions functions = FirebaseFunctions.instance;
  User? firebaseUser;

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  _initializeStream({
    required BuildContext context,
    required String token,
    required User user,
  }) async {
    final client = sc.StreamChatClient(
      streamKey,
      logLevel: sc.Level.OFF,
    );

    await client.connectUser(
      sc.User(
        id: user.uid,
        extraData: {
          'name': user.displayName,
          'image': user.photoURL,
        },
      ),
      token,
    );

    final channel = client.channel('messaging', id: 'general');
    await channel.watch();

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => MaterialApp(
        builder: (context, widget) {
          return sc.StreamChat(
            child: widget,
            client: client,
          );
        },
        debugShowCheckedModeBanner: false,
        home: ChannelListPage(channel),
      ),
    ));
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
          _initializeStream(
            context: context,
            token: token,
            user: firebaseUser!,
          );
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

        _initializeStream(
          context: context,
          token: token,
          user: firebaseUser!,
        );
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

        _initializeStream(
          context: context,
          token: token,
          user: firebaseUser!,
        );
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

    // Sign out Firebase.
    await auth.signOut();
    print('Firebase signed out');
  }
}
