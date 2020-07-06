import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../server.dart';
import 'messages_repository.dart';

enum MessagePagination { previous, next }

class OldMessagesPaginator {
  static const _listingLimitSize = 50;
  final _paginationController = StreamController<MessagePagination>();
  final _messages = BehaviorSubject<List<Message>>.seeded([]);
  final DateTime partitionTime;
  final MessagesRepository _repository;

  bool _isInitialized = false;

  OldMessagesPaginator(this.partitionTime, this._repository);

  Sink<MessagePagination> get pagination => _paginationController.sink;
  Stream<List<Message>> get messages => _messages.stream;

  bool get isInitialized => _isInitialized;

  bool _hasFirstMessage = false;
  bool _hasLastMessage = false;
  bool get hasLastMessage => _hasLastMessage;

  void initialize(ReadPosition /* nullable */ readPosition) async {
    assert(_messages.value.isEmpty);

    if (readPosition != null &&
        readPosition.messageSentAt.isBefore(partitionTime)) {
      await _initializeWithMessagesAround(readPosition.messageSentAt);
    } else {
      await _initializeWithMessagesAround(partitionTime);
    }
    _initializePaginationController();
    _isInitialized = true;
  }

  Future<void> reInitializeWithPartitionTime() async {
    _isInitialized = false;
    await _initializeWithMessagesAround(partitionTime);
    _isInitialized = true;
  }

  Future<void> _addPreviousMessages() async {
    if (_hasFirstMessage) return;

    final messages = _messages.value;

    var sentAt;
    if (messages.isEmpty) {
      _hasLastMessage = true;
      sentAt = partitionTime;
    } else {
      sentAt = messages.first.sentAt;
    }

    final result = await _repository.listBefore(sentAt, _listingLimitSize);
    if (result.length < _listingLimitSize) {
      _hasFirstMessage = true;
    }
    _messages.value = messages..insertAll(0, result);
  }

  Future<void> _addNextMessages() async {
    if (_hasLastMessage) return;

    final messages = _messages.value;
    final sentAt = messages.isNotEmpty ? messages.last.sentAt : partitionTime;
    final result =
        await _repository.listAfter(sentAt, _listingLimitSize, partitionTime);
    if (result.length < _listingLimitSize) {
      _hasLastMessage = true;
    }
    _messages.value = messages..addAll(result);
  }

  Future<void> _initializeWithMessagesAround(DateTime sentAt) async {
    if (sentAt == partitionTime) {
      await _addPreviousMessages();
    } else {
      final result = await _repository.listAround(
          sentAt, _listingLimitSize, partitionTime);

      if (result.reversed
              .takeWhile((value) => !value.sentAt.isBefore(sentAt))
              .length <
          _listingLimitSize) {
        _hasLastMessage = true;
      }

      _messages.value = result;
    }
  }

  void _initializePaginationController() {
    _paginationController.stream
        .throttleTime(const Duration(milliseconds: 500))
        .asyncMap((input) async {
      switch (input) {
        case MessagePagination.previous:
          await _addPreviousMessages();
          break;
        case MessagePagination.next:
          await _addNextMessages();
          break;
      }
    }).listen((_) {});
  }

  void dispose() async {
    await _paginationController.close();
    await _messages.close();
  }
}
