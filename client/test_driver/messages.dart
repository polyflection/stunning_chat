import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final completer = Completer<String>();
  enableFlutterDriverExtension(handler: (_) => completer.future);
  tearDownAll(() => completer.complete(null));

  group('$Firestore', () {
    Firestore firestore;

    setUpAll(() async {
      final firebaseOptions = const FirebaseOptions(
        googleAppID: '1:344501474964:android:c54e3ecee81809b4c80681',
        apiKey: 'AIzaSyDU9sMmDA1kO30ZC9YLQL28lOO8H2bjyGA',
        projectID: 'stunningchat-it',
      );
      final app = await FirebaseApp.configure(
        name: 'test',
        options: firebaseOptions,
      );
      firestore = Firestore(app: app);
    });

    test('getDocumentsFromCollection', () async {
      await firestore.collection('messages').add({'message': 'Hello world!'});
      final query = firestore
          .collection('messages')
          .where('message', isEqualTo: 'Hello world!')
          .limit(1);
      final querySnapshot = await query.getDocuments();
      expect(querySnapshot.metadata, isNotNull);
      expect(querySnapshot.documents.first['message'], 'Hello world!');
    });
  });
}
