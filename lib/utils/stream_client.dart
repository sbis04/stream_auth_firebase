import 'package:flutter/material.dart';
import 'package:stream_auth_firebase/screens/channel_list_page.dart';
import 'package:stream_auth_firebase/utils/authentication.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../secrets.dart';

class StreamClient {
  static final client = StreamChatClient(
    streamKey,
    logLevel: Level.OFF,
  );

  static initialize(String token, BuildContext context) async {
    final authenticatedUser = Authentication.firebaseUser!;

    await client.connectUser(
      User(
        id: authenticatedUser.uid,
        extraData: {
          'name': authenticatedUser.displayName,
          'image': authenticatedUser.photoURL,
        },
      ),
      token,
    );

    final channel = client.channel('messaging', id: 'general');
    await channel.watch();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MaterialApp(
          builder: (context, widget) {
            return StreamChat(
              child: widget,
              client: client,
            );
          },
          debugShowCheckedModeBanner: false,
          home: ChannelListPage(channel),
        ),
      ),
    );
  }
}
