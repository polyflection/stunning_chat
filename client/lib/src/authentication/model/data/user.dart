abstract class User {
  UserKind get kind;
  bool get isAuthenticated;
}

enum UserKind { anonymousUser, visitor }

class AnonymousUser implements User {
  @override
  final UserKind kind = UserKind.anonymousUser;
  final String id;
  final String name;
  @override
  final bool isAuthenticated = true;
  AnonymousUser(this.id, this.name);
}

const visitor = Visitor();

class Visitor implements User {
  @override
  final UserKind kind = UserKind.visitor;
  @override
  final bool isAuthenticated = false;
  const Visitor();
}
