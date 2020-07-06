import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../server.dart' as i;
import '../data/data.dart';
import '../server_repositories.dart';
import 'message/message_creator.dart';
import 'message/message_parser.dart';
import 'message/messages.dart';
import 'message/messages_paginator.dart';
import 'message/messages_repository.dart';
import 'message/read_positions.dart';

class ChannelComponent implements i.Channel {
  final _messageCreator = BehaviorSubject<MessageComposer>();
  final _messageSentController = StreamController<String>.broadcast();
  final i.You _you;
  final MessagesComponent _messages;
  final ReadPositions _readPositions;
  final MessageAddingRepository _messageAddingRepository;
  Channel _data;
  bool _hasRunInitializer = false;
  StreamSubscription<void> _messageSentSubscription;

  factory ChannelComponent(Channel channel, i.You you,
      MessageParser messageParser, ServerRepositories repositories) {
    final messages = MessagesComponent(
        repositories.messagesRepository(channel.id, messageParser));
    final messageAddingRepository =
        repositories.messageAddingRepository(channel.id);
    final readPositions =
        ReadPositions(channel.id, repositories.messagePositionStorage());
    return ChannelComponent.__(
        channel, messages, readPositions, you, messageAddingRepository);
  }

  ChannelComponent.__(this._data, this._messages, this._readPositions,
      this._you, this._messageAddingRepository);

  bool get hasRunInitializer => _hasRunInitializer;

  @override
  Sink<MessagePagination> get messagePagination => _messages.messagePagination;
  @override
  Sink<ReadPosition> get messageReadPosition => _readPositions.position;

  @override
  Stream<i.Messages> get messages => _messages.messages;

  @override
  Stream<ReadPosition> get messageLastReadPosition =>
      _readPositions.lastReadPosition;

  @override
  Stream<ReadPosition> get messageAlreadyReadPosition =>
      _readPositions.alreadyReadPosition;

  @override
  Stream<i.MessageComposer> get messageCreator => _messageCreator.stream;
  @override
  Stream<void> get messageSent => _messageSentController.stream;
  @override
  Stream<String> get name => Stream.value(_data.name);

  Channel get data => _data;

  Future<void> initialize() async {
    _hasRunInitializer = true;
    _updateMessageCreator();
    await _readPositions.initialize();
    await _messages.initialize(await _readPositions.lastReadPosition.first);

    _messageSentSubscription = _messageSentController.stream.listen((_) {
      _updateMessageCreator();
      _messages.sent.add(null);
    });
  }

  void _updateMessageCreator() {
    _messageCreator.value?.dispose();
    _messageCreator.value = MessageComposer(
        _you, _messageAddingRepository, _messageSentController.sink);
  }

  void updateData(Channel data) {
    _data = data;
  }

  void dispose() {
    _messageCreator.close();
    _messageSentController.close();
    _messageSentSubscription?.cancel();
  }
}
