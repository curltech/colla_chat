import 'package:flutter/material.dart';

import '../constant/base.dart';

/// 不同语言版本的下拉选择框的选项
final localeOptions = [
  Option('中文', 'zh_CN'),
  Option('繁体中文', 'zh_TW'),
  Option('English', 'en_US'),
  Option('日本語', 'ja_JP'),
  Option('한국어', 'ko_KR')
];

class LocaleDataProvider with ChangeNotifier {
  String _locale = 'zh_CN';

  Locale getLocale() {
    var locales = _locale.split('_');
    return Locale(locales[0], locales[1]);
  }

  setLocale(Locale locale) {
    _locale = locale.toString();
  }

  String get locale => _locale.toString();

  set locale(String locale) {
    _locale = locale;
    notifyListeners();
  }
}
