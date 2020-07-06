import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../navigator.dart';
import '../../model/server.dart';
import 'channel_creating_page.dart';
import 'left_drawer_subject.dart';

class LeftDrawer extends StatelessWidget {
  static Widget inSubject({Key key}) {
    return Provider<LeftDrawerSubject>(
      key: key,
      create: (context) => LeftDrawerSubject(
        Provider.of<Server>(context, listen: false),
        Provider.of<AppNavigator>(context, listen: false),
      ),
      child: const LeftDrawer._(),
    );
  }

  const LeftDrawer._();

  @override
  Widget build(BuildContext context) {
    final subject = Provider.of<LeftDrawerSubject>(context);
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Stunning Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: StreamBuilder<String>(
                      stream: subject.yourName,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('');
                        return Text('You: ${snapshot.data}');
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: RaisedButton(
                      onPressed: subject.leaveServerButtonPressed,
                      child: const Text('Leave Server'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: const Text('CHANNELS'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return ChannelCreatingPage(subject.server);
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<ChannelStatuses>(
              stream: subject.channels,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(),
                  );
                }

                final channels = snapshot.data;

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return ListTile(
                      title: Text(
                        '#  ${channel.name}',
                        style: TextStyle(
                            fontWeight: channel.isCurrent
                                ? FontWeight.bold
                                : FontWeight.w300),
                      ),
                      onTap: () {
                        subject.switchChannel(channel.id, context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
