import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:server/member_created_function.dart' as member_created;
import 'package:server/message_created_function.dart' as message_created;

void main() {
  functions
    ..[FunctionKey.memberCreated.key] = member_created.function
    ..[FunctionKey.messageCreated.key] = message_created.function;
}

/// The cloud function keys.
enum FunctionKey {
  memberCreated,
  messageCreated,
}

extension KeyName on FunctionKey {
  /// Return enum element part string.
  /// For example, "CloudFunction.hello -> hello".
  String get key => toString().split('.').last;
}
