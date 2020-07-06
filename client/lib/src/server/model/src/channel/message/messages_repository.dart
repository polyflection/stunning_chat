import 'package:async/async.dart';
import 'package:client_server/firebase.dart' as cs;
import 'package:client_server/foundation.dart' hide describeEnum;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../../firestore/firestore.dart';
import '../../../server.dart';
import 'message_parser.dart';

@immutable
class MessageAddingRepository with FirestoreInstance {
  final String _serverId;
  final String _channelId;

  MessageAddingRepository(this._serverId, this._channelId);

  Future<Result<String>> add(String body, You sender) async {
    var json = cs.MessageDocumentData(
      type: describeEnum(MessageType.member),
      body: body,
      sender: sender.id,
      senderName: sender.name,
    ).toJson();

    replaceDocumentIdWithDocumentReference(
        json, cs.MessageDocumentData.senderFieldName,
        reference: firestore.document(
            cs.firestorePath.member(_serverId, sender.id).toString()));
    replaceDateTimeWithServerTimestamp(json, cs.TimestampFields.fieldNames);

    return Result.capture(() async {
      final ref = await Firestore.instance
          .collection(
              cs.firestorePath.messages(_serverId, _channelId).toString())
          .add(json);
      return ref.documentID;
    }());
  }
}

class MessagesRepository with FirestoreInstance {
  final String _serverId;
  final String _channelId;
  final MessageParser _messageParser;

  MessagesRepository(this._serverId, this._channelId, this._messageParser);

  CollectionReference get _messagesCollection => firestore
      .collection(cs.firestorePath.messages(_serverId, _channelId).toString());

  Stream<Iterable<cs.DataChange<Message>>> changes(DateTime startAt) {
    assert(startAt != null);

    return _messagesCollection
        .orderBy(cs.CreatedAt.fieldName)
        .startAt([startAt])
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.documentChanges.map((change) {
              var changeType;
              switch (change.type) {
                case DocumentChangeType.added:
                  changeType = cs.ChangeType.added;
                  break;
                case DocumentChangeType.modified:
                  changeType = cs.ChangeType.modified;
                  break;
                case DocumentChangeType.removed:
                  changeType = cs.ChangeType.removed;
                  break;
              }
              return cs.DataChange(changeType, _toData(change.document),
                  change.oldIndex, change.newIndex);
            });
          },
        );
  }

  Future<List<Message>> listBefore(DateTime sentAt, int limit) async {
    final snapshot = await _messagesCollection
        .orderBy(cs.CreatedAt.fieldName, descending: true)
        .limit(limit)
        .startAfter([sentAt]).getDocuments();
    return snapshot.documents.reversed.map(_toData).toList();
  }

  Future<List<Message>> listAfter(
      DateTime sentAt, int limit, DateTime endBefore) async {
    final snapshot = await _messagesCollection
        .orderBy(cs.CreatedAt.fieldName)
        .limit(limit)
        .startAfter([sentAt]).endBefore([endBefore]).getDocuments();
    return snapshot.documents.map(_toData).toList();
  }

  Future<List<Message>> listAround(
      DateTime sentAt, int limit, DateTime endBefore) async {
    final lists = await Future.wait([
      listBefore(sentAt, limit),
      _messagesCollection
          .orderBy(cs.CreatedAt.fieldName)
          .limit(limit)
          .startAt([sentAt])
          .endBefore([endBefore])
          .getDocuments()
          .then((s) => s.documents.map(_toData).toList())
    ]);
    return lists.first + lists.last;
  }

  Message _toData(DocumentSnapshot snapshot) {
    final json = snapshot.data;
    convertTimeStampToDateTimeString(json, cs.TimestampFields.fieldNames);
    convertDocumentReferenceToDocumentId(
        json, [cs.MessageDocumentData.senderFieldName]);
    final documentData = cs.MessageDocumentData.fromJson(json);

    return Message(
        snapshot.documentID,
        stringToEnum(documentData.type, MessageType.values),
        _messageParser.parse(documentData.body),
        documentData.sender,
        documentData.senderName,
        documentData.createdAt);
  }
}
