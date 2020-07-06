part of server;

@immutable
class Messages extends UnmodifiableListView<Message> {
  Messages(Iterable<Message> source) : super(source);
}

class Message {
  final String id;
  final MessageType type;
  final MessageBody body;
  final MessageSender sender;
  final /*nullable*/ DateTime sentAt;
  String _sentAtView;

  Message(this.id, this.type, this.body, String senderId, String senderName,
      this.sentAt)
      : sender = MessageSender._(UserId(senderId), senderName);

  String get sentAtView => _sentAtView ??= '';
  bool get isSending => sentAt == null;

  @override
  String toString() {
    return body.debugSourceText;
  }
}

abstract class MessageComposer {
  Sink<String> get updateBody;
  Sink<void> get send;
  Stream<bool> get canSend;
}

@immutable
class MessageSender {
  MessageSender._(this._userId, this.name);
  final UserId _userId;
  final String name;
  String get id => _userId.value;
}
