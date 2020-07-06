import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/model/authentication.dart';
import '../../navigator.dart';
import '../model/server.dart';

class ServerLeaving extends StatelessWidget {
  static Widget inSubject(
      {Key key,
      @required Authentication authentication,
      @required Server server,
      @required AppNavigator navigator}) {
    return Provider(
      key: key,
      create: (_) => _Subject(authentication, server, navigator),
      lazy: false,
      child: const ServerLeaving._(),
    );
  }

  const ServerLeaving._();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Text(
            'Bye!👋',
            style: Theme.of(context).textTheme.headline3,
          ),
        ),
      ),
    );
  }
}

class _Subject {
  final Authentication _authentication;
  final Server _server;
  final AppNavigator _navigator;

  _Subject(this._authentication, this._server, this._navigator) {
    run();
  }

  void run() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (await leaveServer(_server)) {
        await _authentication.signOut();
        await _navigator.toSignIn();
      }
    });
  }
}
