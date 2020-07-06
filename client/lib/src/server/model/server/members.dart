part of server;

class Members extends UnmodifiableListView<Member> {
  final You _you;
  Members(Iterable<Member> source, this._you) : super(source);
  bool isYou(Member member) => member.id == _you.id;
}

@immutable
abstract class Member {
  String get id;
  String get name;
}

class You {
  final Member _member;
  You(this._member);
  String get id => _member.id;
  String get name => _member.name;
}
