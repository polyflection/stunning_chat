import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'data/user.dart';

export 'data/user.dart';

// ChangeNotifier or ValueNotifier could be easier.
class Authentication {
  final _userController = BehaviorSubject<User>();

  Authentication() {
    _firebaseAuth.currentUser().then((firebaseUser) {
      _updateUser(firebaseUser);
      _firebaseAuth.onAuthStateChanged.listen(_updateUser);
    });
  }

  Stream<AnonymousUser> get signedIn =>
      _userController.stream.whereType<AnonymousUser>();
  Stream<User> get currentUser =>
      _userController.stream.where((user) => user != null);
  Future<bool> get isUserAuthenticated =>
      currentUser.first.then(_isUserAuthenticated);

  Future<void> signInAnonymously() async {
    if (_user is AnonymousUser) return;
    await _firebaseAuth.signInAnonymously();
  }

  Future<void> signOut() async {
    if (_user is Visitor) return;
    await _firebaseAuth.signOut();
  }

  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  User get _user => _userController.value;
  bool _isUserAuthenticated(User user) => user is! Visitor;

  void _updateUser(FirebaseUser firebaseUser) {
    final user =
        firebaseUser == null ? visitor : _toAnonymousUser(firebaseUser);
    _userController.add(user);
  }

  AnonymousUser _toAnonymousUser(FirebaseUser fbUser) {
    assert(fbUser.isAnonymous);
    return AnonymousUser(fbUser.uid, _generateAnonymousName(fbUser));
  }

  String _generateAnonymousName(FirebaseUser fbUser) {
    return fbUser.uid.substring(0, 10);
  }
}
