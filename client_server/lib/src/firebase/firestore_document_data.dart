import 'package:client_server/firebase.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'firestore_lib/data.dart';

part 'firestore_document_data.g.dart';

@JsonSerializable()
class ServerDocumentData implements CreatedAt {
  final String name;
  @override
  final DateTime createdAt;

  ServerDocumentData({@required this.name, this.createdAt});

  factory ServerDocumentData.fromJson(Map<String, dynamic> json) =>
      _$ServerDocumentDataFromJson(json);

  Map<String, dynamic> toJson() => _$ServerDocumentDataToJson(this);
}

@JsonSerializable()
class ChannelDocumentData implements CreatedAt {
  static const String nameFieldName = 'name';
  final String name;

  static const String createdMemberFieldName = 'createdMember';

  /// Member documentId.
  /// After serializing, it needs to be converted to Firestore Member DocumentReference.
  /// Before de-serializing, Firestore Member DocumentReference needs to convert to the Member documentId.
  ///
  /// Null if it is default channel which is created by system.
  final /*nullable*/ String createdMember;

  @override
  final DateTime createdAt;
  ChannelDocumentData(
      {@required this.name, @required this.createdMember, this.createdAt});

  factory ChannelDocumentData.fromJson(Map<String, dynamic> json) {
    return _$ChannelDocumentDataFromJson(json);
  }

  String get createdMemberId => createdMember;

  Map<String, dynamic> toJson() => _$ChannelDocumentDataToJson(this);
}

@JsonSerializable()
class ChannelNamesDocumentData implements TimestampFields {
  static const String listFieldName = 'list';
  final List<String> list;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  ChannelNamesDocumentData(
      {@required this.list, this.createdAt, this.updatedAt});

  factory ChannelNamesDocumentData.fromJson(Map<String, dynamic> json) {
    return _$ChannelNamesDocumentDataFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ChannelNamesDocumentDataToJson(this);
}

@JsonSerializable()
class MemberDocumentData implements CreatedAt {
  static const String nameFieldName = 'name';
  final String name;
  @override
  final DateTime createdAt;

  MemberDocumentData({@required this.name, @required this.createdAt});

  factory MemberDocumentData.fromJson(Map<String, dynamic> json) {
    return _$MemberDocumentDataFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MemberDocumentDataToJson(this);
}

@JsonSerializable()
class MessageDocumentData implements TimestampFields {
  final String body;

  /// Member documentId.
  /// After serializing, it needs to be converted to Firestore Member DocumentReference.
  /// Before de-serializing, Firestore Member DocumentReference needs to convert to the Member documentId.
  final String sender;
  static const String senderFieldName = 'sender';
  final String senderName;
  static const String typeFieldName = 'type';
  final String type;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  MessageDocumentData(
      {@required this.body,
      @required this.sender,
      @required this.senderName,
      @required this.type,
      this.createdAt,
      this.updatedAt});

  factory MessageDocumentData.fromJson(Map<String, dynamic> json) =>
      _$MessageDocumentDataFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDocumentDataToJson(this);
}
