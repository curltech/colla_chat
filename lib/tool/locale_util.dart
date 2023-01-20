import 'package:flutter/material.dart';

class LocaleUtil {
  static Locale getLocale(String locale) {
    var locales = locale.split('_');
    return Locale(locales[0], locales[1]);
  }
}
