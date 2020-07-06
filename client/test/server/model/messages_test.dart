import 'dart:async';

import 'package:async/async.dart';
import 'package:client_server/firebase.dart';
import 'package:mockito/mockito.dart';
import 'package:stunning_chat_app/src/server/model/server.dart';
import 'package:stunning_chat_app/src/server/model/src/channel/message/message_parser.dart';
import 'package:stunning_chat_app/src/server/model/src/channel/message/messages.dart';
import 'package:stunning_chat_app/src/server/model/src/channel/message/messages_repository.dart';
import 'package:test/test.dart';

class FakeMessagesRepository extends Fake implements MessagesRepository {
  // ignore: close_sinks
  final changesController = StreamController<Iterable<DataChange<Message>>>();

  @override
  Stream<Iterable<DataChange<Message>>> changes(DateTime startAfter) =>
      changesController.stream;

  Future<List<Message>> listAroundResult;

  @override
  Future<List<Message>> listAround(
      DateTime sentAt, int limit, DateTime endBefore) async {
    return listAroundResult;
  }

  @override
  Future<List<Message>> listBefore(DateTime sentAt, int limit) async {
    return listAroundResult;
  }
}

void main() {
  group('initialize.', () {
    FakeMessagesRepository repository;
    MessagesComponent messages;
    ReadPosition readPosition;
    final partitionTime = DateTime(2020, 6, 10, 0, 0, 0);

    ReadPosition beforePartitionPosition() => ReadPosition(
        partitionTime.subtract(const Duration(milliseconds: 1)), 0);
    ReadPosition atPartitionPosition() => ReadPosition(partitionTime, 0);

    Future<List<Message>> listAround() {
      return Future.value(<Message>[
        Message(
            '-2',
            MessageType.member,
            parseMessageBody('a message body -2', [], []),
            'aUserId',
            'aUserName',
            messages.partitionTime.subtract(const Duration(milliseconds: 2))),
        Message(
            '-1',
            MessageType.member,
            parseMessageBody('a message body -1', [], []),
            'aUserId',
            'aUserName',
            messages.partitionTime.subtract(const Duration(milliseconds: 1))),
      ]);
    }

    Future<Iterable<DataChange<Message>>> changes() {
      return Future.delayed(const Duration(seconds: 0), () {
        return [
          DataChange(
              ChangeType.added,
              Message(
                  '1',
                  MessageType.member,
                  parseMessageBody('a message body 1', [], []),
                  'aUserId',
                  'aUserName',
                  messages.partitionTime),
              -1,
              0),
          DataChange(
              ChangeType.added,
              Message(
                  '2',
                  MessageType.member,
                  parseMessageBody('a message body 2', [], []),
                  'aUserId',
                  'aUserName',
                  messages.partitionTime.add(const Duration(milliseconds: 1))),
              -1,
              1)
        ];
      });
    }

    setUp(() {
      repository = FakeMessagesRepository();
      messages = MessagesComponent(repository)..partitionTime = partitionTime;
    });

    group('When messages are only before the partition.', () {
      setUp(() {
        repository.listAroundResult = listAround();
      });
      group('When read position is before the partition.', () {
        setUp(() {
          readPosition = beforePartitionPosition();
        });
        test('emitMessagesOfPaginator.', () async {
          await emitMessagesOfPaginator(messages, readPosition);
        });
      });
      group('When read position is at or after the partition.', () {
        setUp(() {
          readPosition = atPartitionPosition();
        });
        test('emitMessagesOfPaginator.', () async {
          await emitMessagesOfPaginator(messages, readPosition);
        });
      });
      group('emitMessagesOfPaginator.', () {
        setUp(() {
          readPosition = null;
        });
        test('emitMessagesOfPaginator.', () async {
          await emitMessagesOfPaginator(messages, readPosition);
        });
      });
    });

    group('When messages are only at or after the partition.', () {
      setUp(() async {
        repository.changesController.add(await changes());
        repository.listAroundResult = Future.value(<Message>[]);
      });
      group('When read position is before the partition.', () {
        setUp(() {
          readPosition = beforePartitionPosition();
        });
        test('emitMessagesOfListener.', () async {
          await emitMessagesOfListener(messages, readPosition);
        });
      });
      group('When read position is at or after the partition.', () {
        setUp(() {
          readPosition = atPartitionPosition();
        });
        test('emitMessagesOfListener.', () async {
          await emitMessagesOfListener(messages, readPosition);
        });
      });
      group('When read position is null.', () {
        setUp(() {
          readPosition = null;
        });
        test('emitMessagesOfListener.', () async {
          await emitMessagesOfListener(messages, readPosition);
        });
      });
    });
    group('When messages are both before and after the partition.', () {
      setUp(() async {
        repository.changesController.add(await changes());
        repository.listAroundResult = Future.value(listAround());
      });
      group('When read position is before the partition.', () {
        setUp(() {
          readPosition = beforePartitionPosition();
        });
        test('emitMessagesOfBothSide.', () async {
          await emitMessagesOfBothSide(messages, readPosition);
        });
      });
      group('When read position is at or after the partition.', () {
        setUp(() {
          readPosition = atPartitionPosition();
        });
        test('emitMessagesOfBothSide.', () async {
          await emitMessagesOfBothSide(messages, readPosition);
        });
      });
      group('When read position is null.', () {
        setUp(() {
          readPosition = null;
        });
        test('emitMessagesOfBothSide.', () async {
          await emitMessagesOfBothSide(messages, readPosition);
        });
      });
    });
  });
}

Future emitMessagesOfPaginator(
    MessagesComponent messages, ReadPosition readPosition) async {
  final queue = StreamQueue(messages.messages);
  await messages.initialize(readPosition);
  final list = await queue.next;
  expect(list, hasLength(2));
  expect(list.first.id, '-2');
  expect(list[1].id, '-1');
}

Future<void> emitMessagesOfBothSide(
    MessagesComponent messages, ReadPosition readPosition) async {
  final queue = StreamQueue(messages.messages);
  await messages.initialize(readPosition);
  final list = await queue.next;
  expect(list, hasLength(4));
  expect(list.first.id, '-2');
  expect(list[1].id, '-1');
  expect(list[2].id, '1');
  expect(list[3].id, '2');
}

Future<void> emitMessagesOfListener(
    MessagesComponent messages, ReadPosition readPosition) async {
  final queue = StreamQueue(messages.messages);
  await messages.initialize(readPosition);
  final list = await queue.next;
  expect(list, hasLength(2));
  expect(list.first.id, '1');
  expect(list[1].id, '2');
}
