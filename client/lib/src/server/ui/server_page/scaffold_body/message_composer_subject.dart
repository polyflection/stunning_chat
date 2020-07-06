import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../resource_provider.dart';
import '../../../model/server.dart';

class MessageComposerSubject implements Resource {
  // This seems to be necessary to prevent from opening virtual keyboard
  // at unexpected timing.
  final FocusNode focusNode = FocusNode();
  final Channel _channel;

  MessageComposerSubject(this._channel);

  Stream<MessageComposer> get messageCreator => _channel.messageCreator;

  void onSendButtonPressed(MessageComposer messageCreator) {
    focusNode.unfocus();
    messageCreator.send.add(null);
  }

  @override
  void dispose() {
    focusNode.dispose();
  }
}
