import 'package:client_server/firebase.dart' as cs;
import 'package:firebase_admin_interop/firebase_admin_interop.dart' as admin;

Future<void> initializeFirestoreData(admin.App app) async {
  final firestore = app.firestore();

  final serverData = admin.DocumentData.fromMap(
      cs.ServerDocumentData(name: cs.soleInstance).toJson())
    ..setTimestamp(
        cs.CreatedAt.fieldName, admin.Timestamp.fromDateTime(DateTime.now()));

  await firestore
      .document(cs.firestorePath.server(cs.soleDocumentId).toString())
      .setData(serverData);

  final channelData = admin.DocumentData.fromMap(
      cs.ChannelDocumentData(name: cs.defaultChannelName, createdMember: null)
          .toJson())
    ..setTimestamp(
        cs.CreatedAt.fieldName, admin.Timestamp.fromDateTime(DateTime.now()));

  await firestore
      .collection(cs.firestorePath.channels(cs.soleDocumentId).toString())
      .add(channelData);

  final channelNamesData = admin.DocumentData.fromMap(
      cs.ChannelNamesDocumentData(
    list: [cs.defaultChannelName],
  ).toJson())
    ..setTimestamp(
        cs.CreatedAt.fieldName, admin.Timestamp.fromDateTime(DateTime.now()))
    ..setTimestamp(
        cs.UpdatedAt.fieldName, admin.Timestamp.fromDateTime(DateTime.now()));

  await firestore
      .document(cs.firestorePath.channelNames(cs.soleDocumentId).toString())
      .setData(channelNamesData);
}
