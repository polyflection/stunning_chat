import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../form_library/form_library.dart';
import '../../../server.dart' as i;
import 'messages_repository.dart';

/// MessageCreator that constrains its interface only Stream and Sink.
///
/// In complex case with some async processing, e.g. network access,
/// this constraints would be meaningful.
///
/// This module is implemented with this constraint
/// because this project is a sample project with using BLoC pattern.
/// Having said that, this is perhaps a not good example of the constraint
/// because the implementation without this constraint
/// could be better for human to reason about in such relatively simple case.
class MessageComposer implements i.MessageComposer {
  final i.You _you;
  final _bodyField = BodyField();
  final _updateBodyController = StreamController<String>();
  final _sendController = StreamController<void>();
  final _canSend = BehaviorSubject<bool>();
  final Sink<void> _sent;
  final MessageAddingRepository _repository;

  MessageComposer(this._you, this._repository, this._sent) {
    _updateBodyController.stream.listen((value) async {
      await _bodyField.setThenValidate(value);
      _canSend.value = _bodyField.isValid;
    });
    _sendController.stream.listen((_) {
      _sendMessage();
    });
  }

  @override
  Sink<String> get updateBody => _updateBodyController.sink;

  @override
  Sink<void> get send => _sendController.sink;

  @override
  Stream<bool> get canSend => _canSend.stream;

  Future<bool> _sendMessage() async {
    if (!await canSend.first) return false;

    _canSend.value = false;

    final result = await _repository.add(_bodyField.value, _you);

    if (result.isValue) {
      _sent.add(result.asValue.value);
      return true;
    } else {
      debugPrint(result.asError.error);
      debugPrint(result.asError.stackTrace.toString());
      return false;
    }
  }

  void dispose() {
    _updateBodyController.close();
    _canSend.close();
    _sendController.close();
  }
}

class BodyField extends Field<String> {
  static const _maxBodyLength = 3000;
  static const _minBodyLength = 1;

  @override
  String validate() {
    if (value.length < _minBodyLength) {
      return 'The message is too short.';
    } else if (value.length > _maxBodyLength) {
      return 'The message is too long.';
    } else {
      return null;
    }
  }
}
