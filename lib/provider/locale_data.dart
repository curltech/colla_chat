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

class LocaleDataProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh', 'CN');

  Locale get locale => _locale;

  set locale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
