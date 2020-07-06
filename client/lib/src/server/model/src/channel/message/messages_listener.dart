import 'dart:async';

import 'package:client_server/firebase.dart';
import 'package:rxdart/rxdart.dart';

import '../../../server.dart';
import 'messages_repository.dart';

class LatestMessagesListener {
  final _messages = BehaviorSubject<List<Message>>.seeded([]);
  final DateTime partitionTime;
  final MessagesRepository _repository;
  StreamSubscription _messagesSubscription;

  LatestMessagesListener(this.partitionTime, this._repository);

  bool get isListening => _messagesSubscription != null;
  Stream<List<Message>> get messages => _messages.stream;

  void listen() {
    assert(!isListening);

    _messagesSubscription =
        _repository.changes(partitionTime).listen((dataChanges) {
      final messages = _messages.value;
      for (final change in dataChanges) {
        switch (change.type) {
          case ChangeType.added:
            messages.insert(change.newIndex, change.data);
            break;
          case ChangeType.modified:
            if (change.oldIndex == change.newIndex) {
              messages[change.oldIndex] = change.data;
            } else {
              messages
                ..removeAt(change.oldIndex)
                ..insert(change.newIndex, change.data);
            }
            break;
          case ChangeType.removed:
            messages.removeAt(change.oldIndex);
            break;
        }
      }
      _messages.value = messages;
    });
  }

  void dispose() {
    _messagesSubscription?.cancel();
    _messages.close();
  }
}
