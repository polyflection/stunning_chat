part of server;

// Component (A.K.A. BLoC)
abstract class Channel {
  Sink<MessagePagination> get messagePagination;
  Sink<ReadPosition> get messageReadPosition;
  Stream<String> get name;
  Stream<Messages> get messages;
  Stream< /*nullable*/ ReadPosition> get messageAlreadyReadPosition;
  Stream< /*nullable*/ ReadPosition> get messageLastReadPosition;
  Stream<MessageComposer> get messageCreator;
  Stream<void> get messageSent;
}

class ChannelSwitcher {
  final Server _server;
  ChannelSwitcher(this._server);

  Sink<String> get switchChannelById => _server.switchChannelById;
}

abstract class ChannelForm extends Form {
  @override
  Sink<ChannelFormFieldInput> get fieldInput;
  Stream<FieldData<String>> get nameField;
}

class ChannelFormFieldInput<V> extends FieldInput<ChannelFormFieldType, V> {
  ChannelFormFieldInput.name(V value) : super(ChannelFormFieldType.name, value);
}

enum ChannelFormFieldType { name }

@immutable
class ChannelStatus {
  final String id;
  final String name;
  final bool isCurrent;
  // TODO: final bool hasUnreadMessages;
  ChannelStatus(this.id, this.name, this.isCurrent);
}

@immutable
class ChannelStatuses extends UnmodifiableListView<ChannelStatus> {
  ChannelStatuses(Iterable<ChannelStatus> source) : super(source);
}
