import 'package:flutter/material.dart';

ThemeData get darkThemeData => ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.grey,
      scaffoldBackgroundColor: Colors.grey[850],
      appBarTheme: AppBarTheme(color: Colors.grey[900]),
    );

Color get greyTextColor => Colors.grey[400];
