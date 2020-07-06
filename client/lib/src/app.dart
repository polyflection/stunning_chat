import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_guarded_page.dart';
import 'authentication/model/authentication.dart';
import 'authentication/ui/sign_in_page.dart';
import 'navigator.dart';
import 'route_name.dart';
import 'server/model/server.dart';
import 'server/model/src/server_repositories.dart';
import 'server/ui/server_leaving_page.dart';
import 'server/ui/server_page.dart';
import 'theme.dart';

class App extends StatelessWidget {
  final AppModel _model;
  final AppNavigator _navigator = AppNavigator();

  App(SharedPreferences sharedPreferences)
      : _model = AppModel(sharedPreferences);

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _navigator,
      child: MaterialApp(
        navigatorKey: _navigator.navigatorKey,
        title: 'Stunning Chat',
        theme: darkThemeData,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case RouteName.signIn:
              return MaterialPageRoute(
                builder: (context) {
                  return SignInPage(_model.authentication);
                },
              );
            case RouteName.serverLeaving:
              return MaterialPageRoute(
                builder: (context) {
                  return AuthGuardedPage(
                    isUserAuthenticated:
                        _model.authentication.isUserAuthenticated,
                    redirectRouteNameOnUnauthenticated: RouteName.signIn,
                    builder: (_) {
                      return FutureBuilder(
                        future: _model.server,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const SizedBox.shrink();
                          }
                          return ServerLeaving.inSubject(
                            authentication: _model.authentication,
                            server: snapshot.data,
                            navigator: _navigator,
                          );
                        },
                      );
                    },
                  );
                },
              );
            case RouteName.server:
            default:
              return MaterialPageRoute(
                builder: (context) {
                  return AuthGuardedPage(
                    isUserAuthenticated:
                        _model.authentication.isUserAuthenticated,
                    redirectRouteNameOnUnauthenticated: RouteName.signIn,
                    builder: (_) {
                      return FutureBuilder(
                        future: _model.server,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const SizedBox.shrink();
                          }
                          return MultiProvider(
                            providers: [
                              Provider<Server>.value(value: snapshot.data),
                              Provider<ChannelSwitcher>(
                                create: (_) => ChannelSwitcher(snapshot.data),
                              ),
                            ],
                            child: ServerPage.inSubject(),
                          );
                        },
                      );
                    },
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class AppModel {
  /// The authentication component.
  final Authentication authentication = Authentication();

  /// The server component.
  final _server = BehaviorSubject<Server>();

  final SharedPreferences _sharedPreferences;

  StreamSubscription _subscription;

  AppModel(this._sharedPreferences) {
    _enterServerOnSignIn();
  }

  /// Get the server component, built right after a user has signed in.
  Future<Server> get server => _server.stream.where((s) => s != null).first;

  // sign in class
  Future<void> _enterServerOnSignIn() async {
    _subscription = authentication.signedIn.listen((user) async {
      _server.value = await enterServer(soleServerId, user,
          (serverId) => ServerRepositories(serverId, _sharedPreferences));
      _server.value.leaved.listen((event) {
        _server.value = null;
      });
    });
  }

  void dispose() {
    _subscription?.cancel();
    _server.close();
  }
}
