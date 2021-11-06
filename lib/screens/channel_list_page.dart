import 'package:flutter/material.dart';
import 'package:stream_auth_firebase/screens/login_page.dart';
import 'package:stream_auth_firebase/utils/authentication.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'channel_page.dart';

class ChannelListPage extends StatelessWidget {
  final Channel channel;

  ChannelListPage(this.channel);

  final _authentication = Authentication();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stream Chat'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) async {
              await _authentication.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'sign_out',
                  child: Text('Sign out'),
                )
              ];
            },
          ),
        ],
      ),
      body: ChannelsBloc(
        child: ChannelListView(
          filter:
              Filter.in_('members', [StreamChat.of(context).currentUser!.id]),
          sort: [SortOption('last_message_at')],
          channelWidget: Builder(
            builder: (context) => ChannelPage(channel),
          ),
        ),
      ),
    );
  }
}
