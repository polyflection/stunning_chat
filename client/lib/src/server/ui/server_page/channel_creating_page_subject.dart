import 'dart:async';

import 'package:flutter/material.dart';

import '../../../form_library/form_library.dart';
import '../../../route_name.dart';
import '../../model/server.dart' as model;

/// This code shows an example of stream based approach (as known as BLoC).
///
/// Though familiar [FormState] approach would be more concise for such a simple case.
/// In that case, for Flutter form's sync validator,
/// the existing channel names list should be updated via a stream
/// to a variable in this subject.
class ChannelCreatingSubject {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final model.Server _server;
  final Completer<ChannelForm> channelForm = Completer();

  ChannelCreatingSubject(this._server) {
    _server.channelForm.first.then((f) {
      channelForm.complete(
        ChannelForm._(f, onCompleted: () {
          Navigator.of(scaffoldKey.currentState.context)
              .pushReplacementNamed(RouteName.server);
        }, onErrorSubmitting: (String errorMessage) {
          scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text(errorMessage),
          ));
        }),
      );
    });
  }

  void dispose() {
    channelForm.future.then((f) => f._dispose());
  }
}

class ChannelForm {
  final model.ChannelForm _form;
  final NameField _nameField;

  StreamSubscription<DefaultFormPhase> _phaseSubscription;

  ChannelForm._(this._form,
      {@required VoidCallback onCompleted,
      @required void Function(String errorMessage) onErrorSubmitting})
      : _nameField = NameField._(_form.fieldInput) {
    _phaseSubscription = _form.phase.listen((phase) {
      switch (phase.phase) {
        case DefaultFormPhaseType.completed:
          onCompleted();
          break;
        case DefaultFormPhaseType.failedSubmitting:
          onErrorSubmitting(phase.explanation);
          break;
        default:
          break;
      }
    });
  }

  Sink<void> get submit => _form.submit;
  Stream<bool> get canSubmit => _form.canSubmit;
  Stream<NameField> get nameField =>
      _form.nameField.map((f) => _nameField.._update(f));

  Stream<bool> get isSubmitting => _form.phase
      .map((phase) => phase.phase == DefaultFormPhaseType.submitting);

  void _dispose() async {
    _nameField._dispose();
    await _phaseSubscription.cancel();
  }
}

class NameField {
  final Sink _fieldSink;
  final TextEditingController controller = TextEditingController();
  final String hintText = 'Channel name';
  String _errorText;

  NameField._(this._fieldSink) {
    controller.addListener(() =>
        _fieldSink.add(model.ChannelFormFieldInput.name(controller.text)));
  }

  String get errorText => _errorText;

  void _update(FieldData<String> value) {
    if (value.value != controller.text) {
      controller.value = controller.value.copyWith(text: value.value);
    }

    _errorText = value.errorText;
  }

  void _dispose() {
    controller.dispose();
  }
}
