import 'package:flutter/widgets.dart';

import '../../../navigator.dart';
import '../../model/server.dart';

class LeftDrawerSubject {
  final Server server;
  final AppNavigator _navigator;
  LeftDrawerSubject(this.server, this._navigator);

  Stream<String> get yourName => server.you.map((y) => y.name);
  Stream<ChannelStatuses> get channels => server.channels;

  void switchChannel(String channelId, BuildContext context) {
    server.switchChannelById.add(channelId);
    Navigator.pop(context);
  }

  void leaveServerButtonPressed() {
    _navigator.toSignOut();
  }
}
