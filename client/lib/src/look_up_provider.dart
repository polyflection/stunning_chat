import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

T lookUp<T>(BuildContext context) => Provider.of<T>(context, listen: false);
