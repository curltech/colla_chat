import 'package:flutter/material.dart';

class LocaleUtil {
  static Locale getLocale(String locale) {
    var locales = locale.split('_');
    if (locales.length == 3) {
      return Locale.fromSubtags(
          languageCode: locales[0],
          scriptCode: locales[1],
          countryCode: locales[2]);
    }
    if (locales.length == 2) {
      return Locale(locales[0], locales[1]);
    }
    if (locales.length == 1) {
      return Locale(locales[0]);
    }
    return const Locale('en', 'US');
  }
}
