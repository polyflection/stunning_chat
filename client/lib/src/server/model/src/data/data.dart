import '../../server.dart' as i;

class Server {
  final String id;
  final String name;
  Server(this.id, this.name);
}

class Channel {
  final String id;
  final String name;
  final DateTime createdAt;
  Channel(this.id, this.name, this.createdAt);
}

class Member implements i.Member {
  @override
  final String name;
  // Nullable.
  final DateTime joinedAt;
  final UserId _userId;
  Member(this._userId, this.name, this.joinedAt);
  @override
  String get id => _userId.value;
}

class UserId {
  final String value;
  UserId(this.value);
}
