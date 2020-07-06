import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../server.dart';

class MessagePositionStorage {
  final SharedPreferences _sharedPreferences;
  MessagePositionStorage(this._sharedPreferences);

  Future< /* nullable */ ReadPosition> getLastReadPositionOf(String channelId) {
    final list =
        _sharedPreferences.getStringList(_lastReadPositionKey(channelId));
    if (list == null) return null;
    return Future.value(ReadPosition.fromList(list));
  }

  Future<bool> setLastReadPositionOf(String channelId, ReadPosition position) {
    return _sharedPreferences.setStringList(
        _lastReadPositionKey(channelId), _serializeReadPosition(position));
  }

  Future< /* nullable */ ReadPosition> getUnreadPositionOf(String channelId) {
    final list =
        _sharedPreferences.getStringList(_unreadPositionKey(channelId));
    if (list == null) return null;
    return Future.value(ReadPosition.fromList(list));
  }

  Future<bool> setUnreadPositionOf(String channelId, ReadPosition position) {
    return _sharedPreferences.setStringList(
        _unreadPositionKey(channelId), _serializeReadPosition(position));
  }

  String _lastReadPositionKey(String channelId) =>
      'messageLastReadPositionOfChannel:$channelId';
  String _unreadPositionKey(String channelId) =>
      'messageUnreadIndexOfChannel:$channelId';

  List<String> _serializeReadPosition(ReadPosition position) => [
        '${position.messageSentAt.millisecondsSinceEpoch}',
        '${position.leadingEdge}'
      ];
}
