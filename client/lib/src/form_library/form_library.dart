library form;

import 'dart:async';

import 'package:meta/meta.dart';

abstract class Form {
  Sink<FieldInput> get fieldInput;
  Sink<void> get submit;
  Stream<bool> get canSubmit;
  Stream<FormPhase> get phase;
}

abstract class FieldInput<T, V> {
  final T type;
  final V value;
  FieldInput(this.type, this.value);
}

class FieldData<V> {
  final V value;
  final String errorText;
  FieldData._(this.value, [this.errorText]);
}

abstract class FormPhase<T, E> {
  T get phase;
  /*nullable*/ E get explanation;
}

class DefaultFormPhase implements FormPhase<DefaultFormPhaseType, String> {
  @override
  final DefaultFormPhaseType phase;
  @override
  final /*nullable*/ String explanation;

  DefaultFormPhase.nil()
      : phase = DefaultFormPhaseType.nil,
        explanation = null;
  DefaultFormPhase.submitting()
      : phase = DefaultFormPhaseType.submitting,
        explanation = null;
  DefaultFormPhase.completed()
      : phase = DefaultFormPhaseType.completed,
        explanation = null;
  DefaultFormPhase.failedSubmitting(String explanation)
      : phase = DefaultFormPhaseType.failedSubmitting,
        explanation = explanation;
}

enum DefaultFormPhaseType { nil, submitting, completed, failedSubmitting }

abstract class Field<T> {
  T /*nullable*/ _value;
  String /*nullable*/ _errorText;
  bool _isPristine = true;

  Field({@required T value}) : _value = value;

  bool get isValid => !_isPristine && errorText == null;
  bool get isNotValid => !isValid;
  T get value => _value;
  String get errorText => _errorText;

  Future<void> setThenValidate(T value) async {
    if (value == _value) return;

    _value = value;
    _isPristine = false;
    _errorText = await Future.sync(validate);
  }

  /// Returns [_errorText].
  @protected
  FutureOr<String> validate();

  FieldData<T> toFieldData() => FieldData._(value, errorText);
}
