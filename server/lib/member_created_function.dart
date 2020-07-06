import 'dart:math';

import 'package:client_server/firebase.dart' as cs;
import 'package:client_server/foundation.dart';
import 'package:client_server/model.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

CloudFunction get function => functions.firestore
    .document('/servers/{serverId}/members/{memberId}')
    .onCreate(_writeWelcomeMessageToDefaultChannelMessagesCollection);

void _writeWelcomeMessageToDefaultChannelMessagesCollection(
    DocumentSnapshot memberDocumentSnapshot, EventContext context) async {
  final queryResult = await memberDocumentSnapshot.reference.parent.parent
      .collection(cs.FirestorePath.channelsCollectionId)
      .where(cs.ChannelDocumentData.nameFieldName,
          isEqualTo: cs.defaultChannelName)
      .limit(1)
      .get();

  if (queryResult.isEmpty) {
    throw StateError('Channel name: ${cs.defaultChannelName} must exist.');
  }
  final document = queryResult.documents.first;

  final memberName = memberDocumentSnapshot.data
      .getString(cs.MemberDocumentData.nameFieldName);
  final messageDocumentData = _randomWelcomeMessageFor(memberName);
  final now = DateTime.now();
  final documentData = DocumentData.fromMap(messageDocumentData.toJson())
    ..setTimestamp(cs.CreatedAt.fieldName, Timestamp.fromDateTime(now))
    ..setTimestamp(cs.UpdatedAt.fieldName, Timestamp.fromDateTime(now));

  final result = await document.reference
      .collection(cs.FirestorePath.messagesCollectionId)
      .add(documentData);

  print('${result.path} created.');
}

cs.MessageDocumentData _randomWelcomeMessageFor(String memberName) {
  final random = Random();
  final messageBody =
      _messageBodies[random.nextInt(_messageBodies.length)](memberName);
  return cs.MessageDocumentData(
      body: messageBody,
      sender: null,
      senderName: 'system',
      type: describeEnum(MessageType.welcome));
}

final _messageBodies = <String Function(String memberName)>[
  (String memberName) => 'Welcome to my server, @$memberName!',
  (String memberName) => 'Hey, listen! @$memberName is coming!',
  (String memberName) => 'Hello, @$memberName.',
];
