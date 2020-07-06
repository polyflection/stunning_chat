import 'dart:async';

import 'package:client_server/foundation.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

CloudFunction get function => functions.firestore
    .document('/servers/{serverId}/channels/{channelId}/messages/{messageId}')
    .onCreate(_handler);

FutureOr<void> _handler(DocumentSnapshot snapshot, EventContext context) {
  // TODO: Parse body, and handle OGP and mention.
  urlPattern;
  print('message created: ${snapshot.data.toMap()}');
}
