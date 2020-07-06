import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../../server.dart';
import 'message_position_storage.dart';

class ReadPositions {
  final _readPositionController = StreamController<ReadPosition>();
  final _LastReadPosition _lastReadPosition;
  final _AlreadyReadPosition _alreadyReadyPosition;

  ReadPositions(String channelId, MessagePositionStorage storage)
      : _lastReadPosition = _LastReadPosition(channelId, storage),
        _alreadyReadyPosition = _AlreadyReadPosition(channelId, storage);

  Sink<ReadPosition> get position => _readPositionController.sink;
  Stream<ReadPosition> get lastReadPosition => _lastReadPosition.position;
  Stream<ReadPosition> get alreadyReadPosition =>
      _alreadyReadyPosition.position;

  Future<void> initialize() {
    _readPositionController.stream
        .where((position) => position.messageSentAt != null)
        .doOnData((position) {
          _lastReadPosition.update(position, persist: false);
          _alreadyReadyPosition.updateIfItMovesForward(position,
              persist: false);
        })
        .throttleTime(const Duration(seconds: 5), trailing: true)
        .listen((position) {
          _lastReadPosition.update(position);
          _alreadyReadyPosition.updateIfItMovesForward(position);
        });

    return Future.wait(
        [_lastReadPosition.initialize(), _alreadyReadyPosition.initialize()]);
  }

  void dispose() {
    _readPositionController.close();
    _lastReadPosition.dispose();
    _alreadyReadyPosition.dispose();
  }
}

class ReadPosition {
  final DateTime messageSentAt;
  final double leadingEdge;

  ReadPosition.fromList(List<String> values)
      : this(DateTime.fromMillisecondsSinceEpoch(int.parse(values.first)),
            double.parse(values.last));

  ReadPosition(this.messageSentAt, this.leadingEdge)
      : assert(messageSentAt != null),
        assert(leadingEdge != null);

  @override
  String toString() =>
      'ReadPosition sentAt: $messageSentAt leadingEdge: $leadingEdge.';

  /// find index in [Messages].
  ///
  /// [Messages] [messageSentAt] list must be sorted.
  /// The exact index of message with particular [messageSentAt] is not always found,
  /// because the message could have been removed.
  /// In that case, smaller index by 1 is returned.
  int findIndexIn(Messages messages) {
    assert(messages != null);

    return findIndexOf(messageSentAt,
        messages.where((m) => m.sentAt != null).map((m) => m.sentAt).toList());
  }

  /// This is modified version of binarySearch in the collection package.
  /// https://api.flutter.dev/flutter/package-collection_collection/binarySearch.html
  @visibleForTesting
  static int findIndexOf(DateTime sentAt, List<DateTime> messageSentAtList) {
    assert(sentAt != null);
    assert(!messageSentAtList.contains(null));

    if (messageSentAtList.isEmpty) return 0;

    var min = 0;
    var max = messageSentAtList.length;
    while (min < max) {
      final mid = min + ((max - min) >> 1);
      final element = messageSentAtList[mid];
      final comp = element.compareTo(sentAt);
      if (comp == 0) {
        return mid;
      }
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return max - 1;
  }
}

class _LastReadPosition {
  final String _channelId;
  final MessagePositionStorage _storage;
  final _position = BehaviorSubject<ReadPosition>();

  _LastReadPosition(this._channelId, this._storage);

  Stream< /*nullable*/ ReadPosition> get position => _position.stream;

  Future<void> initialize() async {
    _position.value = await _storage.getLastReadPositionOf(_channelId);
  }

  Future<bool> update(ReadPosition readPosition, {bool persist = true}) async {
    assert(readPosition != null);

    _position.value = readPosition;

    if (persist) {
      return _storage.setLastReadPositionOf(_channelId, _position.value);
    }

    return true;
  }

  void dispose() {
    _position.close();
  }
}

class _AlreadyReadPosition {
  final String _channelId;
  final MessagePositionStorage _storage;
  final _position = BehaviorSubject<ReadPosition>();

  _AlreadyReadPosition(this._channelId, this._storage);

  Stream< /*nullable*/ ReadPosition> get position => _position.stream;

  Future<void> initialize() async {
    _position.value = await _storage.getUnreadPositionOf(_channelId);
  }

  Future<bool> updateIfItMovesForward(ReadPosition newReadPosition,
      {bool persist = true}) async {
    assert(newReadPosition != null);

    if (_position.value != null &&
        !newReadPosition.messageSentAt.isAfter(_position.value.messageSentAt)) {
      return false;
    }

    _position.value = newReadPosition;

    if (persist) {
      return _storage.setUnreadPositionOf(_channelId, newReadPosition);
    }

    return true;
  }

  void dispose() {
    _position.close();
  }
}
