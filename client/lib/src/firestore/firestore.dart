import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:meta/meta.dart';

void convertTimeStampToDateTimeString(
    Map<String, dynamic> json, List<String> fieldNames) {
  for (final fieldName in fieldNames) {
    final value = json[fieldName];
    assert(value == null || value is fs.Timestamp);
    json[fieldName] = _timeStampToDateTime(value)?.toIso8601String();
  }
}

void replaceDateTimeWithServerTimestamp(
    Map<String, dynamic> json, List<String> fieldNames) {
  final serverTimestamp = fs.FieldValue.serverTimestamp();
  for (final fieldName in fieldNames) {
    json[fieldName] = serverTimestamp;
  }
}

void convertDocumentReferenceToDocumentId(
    Map<String, dynamic> json, List<String> fieldNames) {
  for (final fieldName in fieldNames) {
    final fs.DocumentReference value = json[fieldName];
    json[fieldName] = value.documentID;
  }
}

void replaceDocumentIdWithDocumentReference(
    Map<String, dynamic> json, String fieldName,
    {@required fs.DocumentReference reference}) {
  json[fieldName] = reference;
}

/*nullable*/ DateTime _timeStampToDateTime(
        fs.Timestamp /*nullable*/ timestamp) =>
    timestamp?.toDate();

mixin FirestoreInstance {
  @protected
  final fs.Firestore firestore = fs.Firestore.instance;
}
