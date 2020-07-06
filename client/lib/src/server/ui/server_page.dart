import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/server.dart';
import 'server_page/left_drawer.dart';
import 'server_page/right_drawer.dart';
import 'server_page/scaffold_body.dart';
import 'server_page_subject.dart';

class ServerPage extends StatelessWidget {
  static Widget inSubject({Key key}) {
    return Provider(
      key: key,
      create: (context) =>
          ServerPageSubject(Provider.of<Server>(context, listen: false)),
      child: const ServerPage._(),
    );
  }

  const ServerPage._();

  @override
  Widget build(BuildContext context) {
    final subject = Provider.of<ServerPageSubject>(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<String>(
            stream: subject.currentChannelName,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('');
              return Text('# ${snapshot.data}');
            },
          ),
          actions: <Widget>[
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.people),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                );
              },
            ),
          ],
        ),
        drawer: LeftDrawer.inSubject(),
        endDrawer: RightDrawer.inSubject(),
        body: ScaffoldBody.inSubject(),
      ),
    );
  }
}
