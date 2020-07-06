import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';

import '../../../server.dart';
import 'messages_listener.dart';
import 'messages_paginator.dart';
import 'messages_repository.dart';
import 'read_positions.dart';

/// Messages component.
///
/// It supervises the paginator and the listener
/// for message list data.dart consistency.
///
/// By app design, modifying or removing a message is not allowed
/// 5 minutes after it it sent.
class MessagesComponent {
  // A member can not modify or remove one's message sent after 5 minutes.
  static const _modifiableMessageLimitTime = Duration(minutes: 5);
  final _sentController = StreamController<String>();

  final MessagesRepository _repository;

  // late final.
  @visibleForTesting
  DateTime partitionTime;

  // late final
  OldMessagesPaginator _paginator;
  // late final
  LatestMessagesListener _listener;

  StreamSubscription _messageSentSubscription;

  MessagesComponent(this._repository);

  DateTime get _partitionTime =>
      partitionTime ??= DateTime.now().subtract(_modifiableMessageLimitTime);

  Sink<MessagePagination> get messagePagination => _paginator.pagination;
  Sink<String> get sent => _sentController.sink;

  Stream<Messages> get messages async* {
    if (_listener == null ||
        !_listener.isListening ||
        _paginator == null ||
        !_paginator.isInitialized) yield Messages([]);

    yield* CombineLatestStream.combine2(_paginator.messages, _listener.messages,
        (List<Message> p, List<Message> l) {
      if (p.isEmpty || _paginator.hasLastMessage) {
        return Messages(p + l);
      } else {
        return Messages(p);
      }
    });
  }

  Future<void> initialize(ReadPosition /*nullable*/ lastReadPosition) async {
    assert(_listener == null);
    assert(_paginator == null);

    _paginator = OldMessagesPaginator(_partitionTime, _repository)
      ..initialize(lastReadPosition);
    _listener = LatestMessagesListener(_partitionTime, _repository)..listen();
    await Future.wait([_paginator.messages.first, _listener.messages.first]);

    unawaited(_sentController.stream.forEach((_) {
      if (!_paginator.hasLastMessage) {
        _paginator.reInitializeWithPartitionTime();
      }
    }));
  }

  void dispose() {
    _messageSentSubscription?.cancel();
    _sentController.close();
    _listener?.dispose();
    _paginator?.dispose();
  }
}
