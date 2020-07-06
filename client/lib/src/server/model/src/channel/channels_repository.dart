import 'package:async/async.dart';
import 'package:client_server/firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../../../../firestore/firestore.dart';
import '../../server.dart';
import '../data/data.dart' as data;

@immutable
class ChannelCreatingRepository with FirestoreInstance {
  final String _serverId;
  ChannelCreatingRepository(this._serverId);

  Future<Result<String>> createChannel(You you, String channelName) async {
    // Firestore transaction will fail on offline. Thus local commit won't occur.
    return Result.capture(() async {
      final resultMap = await firestore.runTransaction((transaction) async {
        final channelNamesRef = firestore
            .document(firestorePath.channelNames(_serverId).toString());
        final channelNameListSnapshot = await transaction.get(channelNamesRef);

        assert(channelNameListSnapshot != null &&
            channelNameListSnapshot.data != null);
        final list = List.castFrom<dynamic, String>(channelNameListSnapshot
            .data[ChannelNamesDocumentData.listFieldName]);
        assert(list != null);
        if (list.contains(channelName)) {
          throw StateError('Channel name $channelName has already taken.');
        }
        list.add(channelName);
        await transaction.update(channelNamesRef, {
          ChannelNamesDocumentData.listFieldName: list,
          UpdatedAt.fieldName: FieldValue.serverTimestamp()
        });

        final newChannelRef = firestore
            .collection(firestorePath.channels(_serverId).toString())
            .document();
        final newChannelData = _buildNewChannelData(channelName, you.id);
        await transaction.set(newChannelRef, newChannelData);

        return {'id': newChannelRef.documentID};
      });

      return resultMap['id'] as String;
    }());
  }

  Map<String, dynamic> _buildNewChannelData(
      String channelName, String createdMemberId) {
    final newChannelData =
        ChannelDocumentData(name: channelName, createdMember: createdMemberId)
            .toJson();

    replaceDateTimeWithServerTimestamp(newChannelData, [CreatedAt.fieldName]);

    replaceDocumentIdWithDocumentReference(
        newChannelData, ChannelDocumentData.createdMemberFieldName,
        reference: firestore.document(
            firestorePath.member(_serverId, createdMemberId).toString()));

    return newChannelData;
  }
}

@immutable
class ChannelsRepository with FirestoreInstance {
  final String _serverId;
  ChannelsRepository(this._serverId);

  Stream<Iterable<DataChange<data.Channel>>> get dataChanges {
    return firestore
        .collection(firestorePath.channels(_serverId).toString())
        .orderBy(CreatedAt.fieldName)
        .snapshots()
        .map((snapshot) {
      return snapshot.documentChanges.map((change) {
        var changeType;
        switch (change.type) {
          case DocumentChangeType.added:
            changeType = ChangeType.added;
            break;
          case DocumentChangeType.modified:
            changeType = ChangeType.modified;
            break;
          case DocumentChangeType.removed:
            changeType = ChangeType.removed;
            break;
        }
        return DataChange(changeType, _toData(change.document), change.oldIndex,
            change.newIndex);
      });
    });
  }

  data.Channel _toData(DocumentSnapshot snapshot) {
    final json = snapshot.data;
    convertTimeStampToDateTimeString(json, [CreatedAt.fieldName]);
    convertDocumentReferenceToDocumentId(
        json, [ChannelDocumentData.createdMemberFieldName]);
    final documentData = ChannelDocumentData.fromJson(json);
    return data.Channel(
        snapshot.documentID, documentData.name, documentData.createdAt);
  }
}
