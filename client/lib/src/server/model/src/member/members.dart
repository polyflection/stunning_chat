import 'dart:async';

import 'package:client_server/firebase.dart';
import 'package:rxdart/rxdart.dart';

import '../../server.dart';
import '../data/data.dart' as data;
import 'members_repository.dart';

class MembersComponent {
  final You you;
  final _members = BehaviorSubject<List<data.Member>>.seeded([]);
  final MembersRepository _repository;
  StreamSubscription _subscription;

  MembersComponent(this.you, this._repository);

  Stream<Members> get members =>
      _members.stream.map((members) => Members(members, you));

  Future<void> initialize() async {
    _subscription = _repository.dataChanges.listen((dataChanges) {
      for (final change in dataChanges) {
        switch (change.type) {
          case ChangeType.added:
            _members.value.insert(change.newIndex, change.data);
            break;
          case ChangeType.modified:
            final member = _members.value.removeAt(change.oldIndex);
            assert(member.id == change.data.id);
            _members.value.insert(change.newIndex, change.data);
            break;
          case ChangeType.removed:
            _members.value.removeAt(change.oldIndex);
            break;
        }
      }
      _members.add(_members.value);
    });

    await members.where((list) => list.isNotEmpty).first;
  }

  Future<void> dispose() async {
    await _members.close();
    await _subscription?.cancel();
  }
}
