import 'package:flutter/material.dart';

class AuthGuardedPage extends StatelessWidget {
  final Future<bool> _isUserAuthenticated;
  final WidgetBuilder _builder;
  final String _routeNameToRedirectOnFailure;

  AuthGuardedPage({
    Key key,
    @required Future<bool> isUserAuthenticated,
    @required String redirectRouteNameOnUnauthenticated,
    @required WidgetBuilder builder,
  })  : assert(isUserAuthenticated != null),
        assert(redirectRouteNameOnUnauthenticated != null),
        assert(builder != null),
        _isUserAuthenticated = isUserAuthenticated,
        _routeNameToRedirectOnFailure = redirectRouteNameOnUnauthenticated,
        _builder = builder,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isUserAuthenticated,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            if (snapshot.data) {
              return _builder(context);
            } else {
              Future.microtask(() => Navigator.of(context)
                  .pushNamed(_routeNameToRedirectOnFailure));
              return const SizedBox.shrink();
            }
            break;
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
