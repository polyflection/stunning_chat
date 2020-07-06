import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/server.dart';

class ScaffoldBodySubject {
  final Server _server;
  ScaffoldBodySubject(this._server);
  Stream<Channel> get currentChannel => _server.currentChannel;

  Key messageListKey(Channel channel) => Key('messageList${channel.hashCode}');
  Key messageComposerKey(Channel channel) =>
      Key('messageComposer${channel.hashCode}');
}
