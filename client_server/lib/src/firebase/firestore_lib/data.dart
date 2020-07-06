typedef ConvertTimeStampToDateTime = Map<String, dynamic> Function<S>(
    Map<String, dynamic> json,
    List<String> fieldNames,
    void Function() converter);

typedef DocumentReferenceConverter = Map<String, dynamic> Function(
    Map<String, dynamic> json, List<String> fieldNames);

abstract class CreatedAt {
  /// Before de-serializing, Firestore Timestamp needs to convert to DateTime.
  DateTime get createdAt;
  static const String fieldName = 'createdAt';
}

abstract class UpdatedAt {
  /// Before de-serializing, Firestore Timestamp needs to convert to DateTime.
  DateTime get updatedAt;
  static const String fieldName = 'updatedAt';
}

abstract class TimestampFields with CreatedAt, UpdatedAt {
  static const List<String> fieldNames = [
    CreatedAt.fieldName,
    UpdatedAt.fieldName
  ];
}
