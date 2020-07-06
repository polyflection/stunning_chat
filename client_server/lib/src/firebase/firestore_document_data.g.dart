// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_document_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerDocumentData _$ServerDocumentDataFromJson(Map<String, dynamic> json) {
  return ServerDocumentData(
    name: json['name'] as String,
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
  );
}

Map<String, dynamic> _$ServerDocumentDataToJson(ServerDocumentData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

ChannelDocumentData _$ChannelDocumentDataFromJson(Map<String, dynamic> json) {
  return ChannelDocumentData(
    name: json['name'] as String,
    createdMember: json['createdMember'] as String,
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
  );
}

Map<String, dynamic> _$ChannelDocumentDataToJson(
        ChannelDocumentData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'createdMember': instance.createdMember,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

ChannelNamesDocumentData _$ChannelNamesDocumentDataFromJson(
    Map<String, dynamic> json) {
  return ChannelNamesDocumentData(
    list: (json['list'] as List)?.map((e) => e as String)?.toList(),
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$ChannelNamesDocumentDataToJson(
        ChannelNamesDocumentData instance) =>
    <String, dynamic>{
      'list': instance.list,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

MemberDocumentData _$MemberDocumentDataFromJson(Map<String, dynamic> json) {
  return MemberDocumentData(
    name: json['name'] as String,
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
  );
}

Map<String, dynamic> _$MemberDocumentDataToJson(MemberDocumentData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

MessageDocumentData _$MessageDocumentDataFromJson(Map<String, dynamic> json) {
  return MessageDocumentData(
    body: json['body'] as String,
    sender: json['sender'] as String,
    senderName: json['senderName'] as String,
    type: json['type'] as String,
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$MessageDocumentDataToJson(
        MessageDocumentData instance) =>
    <String, dynamic>{
      'body': instance.body,
      'sender': instance.sender,
      'senderName': instance.senderName,
      'type': instance.type,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
