import 'package:flutter/widgets.dart';
import 'route_name.dart';

class AppNavigator {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Future<void> toSignOut() async {
    await _navigatorState.pushNamedAndRemoveUntil(
        RouteName.serverLeaving, (route) => route.isFirst);
  }

  Future<void> toSignIn() async {
    await _navigatorState.pushNamed(RouteName.signIn);
  }

  NavigatorState get _navigatorState => navigatorKey.currentState;
}
