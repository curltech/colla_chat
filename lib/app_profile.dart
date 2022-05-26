import 'package:flutter/material.dart';

class AppProfile with ChangeNotifier {
  ThemeData _themeData = ThemeData(primarySwatch: Colors.cyan);

  ThemeData get themeData {
    return _themeData;
  }

  set primarySwatch(MaterialColor color) {
    _themeData = ThemeData(primarySwatch: color);
    notifyListeners();
  }
}
