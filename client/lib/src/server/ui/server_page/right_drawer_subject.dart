import 'dart:collection';
import '../../model/server.dart';

class RightDrawerSubject {
  final Server _server;
  RightDrawerSubject(this._server);

  Stream<UnmodifiableListView<Member>> get members =>
      _server.members.map((members) => UnmodifiableListView(members.map(
          (member) => Member(member.id, member.name, members.isYou(member)))));

  Stream<int> get numberOfTeamMembers => members.map((m) => m.length);
}

class Member {
  final String iconCharacter;
  final String id;
  final String name;
  final bool isYou;
  Member(this.id, String name, this.isYou)
      : iconCharacter = name.substring(0, 1),
        name = isYou ? '$name (You)' : name;
}
