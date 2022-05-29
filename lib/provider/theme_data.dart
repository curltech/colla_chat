import 'package:flutter/material.dart';

class ThemeDataProvider with ChangeNotifier {
  ThemeData _themeData = ThemeData(primarySwatch: Colors.cyan);

  ThemeData get themeData {
    ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: Colors.cyan);
    return _themeData;
  }

  set primarySwatch(MaterialColor color) {
    _themeData = ThemeData(primarySwatch: color);
    notifyListeners();
  }
}
