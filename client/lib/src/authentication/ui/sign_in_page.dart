import 'package:flutter/material.dart';

import '../../route_name.dart';
import '../model/authentication.dart';

class SignInPage extends StatefulWidget {
  final Authentication _authentication;
  SignInPage(this._authentication);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to our Stunning Chat!'),
        leading: const Icon(Icons.chat),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'You can enter our sole chat server as an anonymous user.',
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
            ),
            _signingIn
                ? const CircularProgressIndicator()
                : RaisedButton(
                    onPressed: () => _handleSignIn(context),
                    child: Text(
                      '👻 Anonymous Sign In 👻',
                      key: const ValueKey('Anonymous sign in'),
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  bool _signingIn = false;

  void _handleSignIn(BuildContext context) async {
    if (_signingIn) return;

    setState(() {
      _signingIn = true;
    });

    try {
      await widget._authentication.signInAnonymously();
    } catch (e) {
      // TODO: show error dialog.
      debugPrint(e);
    }

    await Navigator.of(context).pushReplacementNamed(RouteName.server);
  }
}
