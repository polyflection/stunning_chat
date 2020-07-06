import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../form_library/form_library.dart';
import '../../server.dart' as i;
import 'channels_repository.dart';

typedef OnCompleted = Future<void> Function(String newChannelId);

class ChannelForm extends i.ChannelForm {
  final i.You _you;
  final ChannelCreatingRepository _repository;
  final _phase =
      BehaviorSubject<DefaultFormPhase>.seeded(DefaultFormPhase.nil());
  final BehaviorSubject<NameField> _nameField;
  final _fieldInputController = StreamController<i.ChannelFormFieldInput>();
  final _submitController = StreamController<void>();
  final OnCompleted _onCompleted;

  ChannelForm(
      this._you, Stream<Iterable<String>> channelNames, this._repository,
      {@required OnCompleted onCompleted})
      : assert(onCompleted != null),
        _nameField = BehaviorSubject.seeded(
            NameField(value: '', channelNames: channelNames)),
        _onCompleted = onCompleted {
    _fieldInputController.stream
        .skipWhile((_) => _phase.value.phase == DefaultFormPhaseType.submitting)
        .asyncMap((input) async {
      switch (input.type) {
        case i.ChannelFormFieldType.name:
          final field = _nameField.value;
          await field.setThenValidate(input.value);
          _nameField.value = field;
          break;
      }
    }).listen((_) {
      if (_phase.value.phase != DefaultFormPhaseType.nil) {
        _phase.add(DefaultFormPhase.nil());
      }
    });

    _submitController.stream.exhaustMap((_) async* {
      final emitFailedSubmittingPhase = () {
        // NOT using addError intentionally,
        // since it's a failure case of this domain, which is NOT program error.
        _phase.add(DefaultFormPhase.failedSubmitting(
            'Failed to create channel. Please try again later.'));
      };

      if (!await canSubmit.first) {
        emitFailedSubmittingPhase();
        return;
      }

      _phase.add(DefaultFormPhase.submitting());

      final result = await _submit();

      if (result.isError) {
        debugPrint(result.asError.error.toString());
        emitFailedSubmittingPhase();
      } else {
        await _onCompleted(result.asValue.value);
        _phase.add(DefaultFormPhase.completed());
      }
    }).listen((_) {});
  }

  @override
  Sink<i.ChannelFormFieldInput> get fieldInput => _fieldInputController.sink;
  @override
  Sink<void> get submit => _submitController.sink;

  @override
  Stream<bool> get canSubmit {
    return CombineLatestStream.combine2(_nameField, phase,
        (NameField nameField, DefaultFormPhase phase) {
      if (phase.phase == DefaultFormPhaseType.submitting) {
        return false;
      }
      return nameField.isValid;
    });
  }

  @override
  Stream<FieldData<String>> get nameField =>
      _nameField.stream.map((f) => f.toFieldData());

  @override
  Stream<DefaultFormPhase> get phase => _phase.stream;

  Future<Result<String>> _submit() async {
    return _repository.createChannel(_you, _nameField.value.value);
  }

  void dispose() async {
    await _nameField.close();
    await _phase.close();
    await _fieldInputController.close();
    await _submitController.close();
  }
}

class NameField extends Field<String> {
  static const _minLength = 1;
  static const _maxLength = 100;
  final Stream<Iterable<String>> _channelNames;

  NameField(
      {String value = '', @required Stream<Iterable<String>> channelNames})
      : assert(channelNames != null),
        _channelNames = channelNames,
        super(value: value);

  @override
  @protected
  Future<String> validate() async {
    if (value.length < _minLength) {
      return 'The channel name cannot be empty.';
    } else if (value.length > _maxLength) {
      return 'The channel name is too long.';
    } else if ((await _channelNames.first).contains(value)) {
      return 'The channel name has already been taken.';
    } else {
      return null;
    }
  }
}
