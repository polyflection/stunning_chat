import 'dart:async';

import '../model/server.dart';

class ServerPageSubject {
  final Server _server;
  ServerPageSubject(this._server);

  // I believe, when StreamBuilder cancels the subscription,
  // the implicit subscription by the await for loop is also cancelled.
  Stream<String> get currentChannelName async* {
    await for (final current in _server.currentChannel) {
      yield* current.name;
    }
  }
}
