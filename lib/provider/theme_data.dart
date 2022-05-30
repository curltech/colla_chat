import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeDataProvider with ChangeNotifier {
  MaterialColor? _primarySwatch = Colors.cyan;
  MaterialColor? _seedColor = Colors.cyan;
  String _fontFamily = 'Lato';
  String _brightness = 'light';
  ThemeData? _themeData;

  ThemeData? get themeData {
    buildThemeData();
    return _themeData;
  }

  buildThemeData() {
    Brightness brightness =
        Brightness.values.firstWhere((element) => element.name == _brightness);
    ColorScheme colorScheme;
    if (_seedColor != null) {
      colorScheme = ColorScheme.fromSeed(
          seedColor: _seedColor ?? Colors.cyan, brightness: brightness);
    } else if (_primarySwatch != null) {
      colorScheme = ColorScheme.fromSwatch(
          primarySwatch: _primarySwatch ?? Colors.cyan, brightness: brightness);
    } else {
      colorScheme =
          ColorScheme.fromSeed(seedColor: Colors.cyan, brightness: brightness);
    }
    TextTheme textTheme;
    if (_fontFamily != '') {
      textTheme = GoogleFonts.getTextTheme(_fontFamily);
    } else {
      textTheme = const TextTheme();
    }

    ThemeData themeData = ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: brightness,
    );
    _themeData = themeData;
  }

  MaterialColor? get seedColor {
    return _seedColor;
  }

  set seedColor(MaterialColor? color) {
    _seedColor = color;
    _primarySwatch = null;
    notifyListeners();
  }

  MaterialColor? get primarySwatch {
    return _primarySwatch;
  }

  set primarySwatch(MaterialColor? color) {
    _seedColor = null;
    _primarySwatch = color;
    notifyListeners();
  }

  String get fontFamily {
    return _fontFamily;
  }

  set fontFamily(String fontFamily) {
    _fontFamily = fontFamily;
    notifyListeners();
  }

  String get brightness {
    return _brightness;
  }

  set brightness(String brightness) {
    _brightness = brightness;
    notifyListeners();
  }
}
