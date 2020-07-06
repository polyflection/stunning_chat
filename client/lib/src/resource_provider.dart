import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Resource interface for [dispose] capability.
///
/// Example: class C implements Resource {}
abstract class Resource {
  void dispose();
}

/// READMEに書く
/// One may prefer https://pub.dev/packages/disposable_provider,
/// providing almost the same functionality but different name.

/// Provider for disposing [Resource] automatically.
///
/// This doesn't have a value named constructor
/// because it is equivalent of [Provider.value].
/// Use [Provider.value] for an existing resource,
/// expected to be disposed somewhere else.
///
/// If an object is a subtype of [ChangeNotifier],
/// use [ChangeNotifierProvider] instead.
class ResourceProvider<T extends Resource> extends Provider<T> {
  static void _dispose(BuildContext context, Resource resource) {
    resource?.dispose();
  }

  /// Creates a [Resource] using `create` and automatically
  /// dispose it when [ResourceProvider] is removed from the widget tree.
  ResourceProvider({
    Key key,
    @required Create<T> create,
    bool lazy,
    TransitionBuilder builder,
    Widget child,
  })  : assert(create != null),
        super(
          key: key,
          create: create,
          dispose: _dispose,
          lazy: lazy,
          builder: builder,
          child: child,
        );
}
