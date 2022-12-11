import 'dart:async';
import 'dart:convert';

import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const defaultLocale = Locale('zh', 'CN');

const supportedLocales = [
  Locale('en', 'US'),
  Locale('zh', 'TW'),
  Locale('ja', 'JP'),
  Locale('ko', 'KR'),
  Locale('zh', 'CN'),
];

/// 自己写的，不是gen_l10n创建的，需要从assets目录加载语言包
/// 使用的方法是：AppLocalizations.instance.text('page_one')
class AppLocalizations {
  static AppLocalizations? current;
  static final Map<Locale, AppLocalizations> _all = {};

  final Map<dynamic, dynamic> _localisedValues;
  final Locale _locale;

  AppLocalizations(this._locale, this._localisedValues);

  static init() async {
    for (var supportedLocale in supportedLocales) {
      await load(supportedLocale);
    }
  }

  static Future<AppLocalizations?> load(Locale locale) async {
    Map<Locale, AppLocalizations> all = AppLocalizations._all;
    AppLocalizations? current = all[locale];
    if (current == null) {
      String jsonContent = await rootBundle
          .loadString("assets/locale/localization_${locale.toString()}.json");
      var localisedValues = json.decode(jsonContent);
      current = AppLocalizations(locale, localisedValues);
      all[locale] = current;
    }
    AppLocalizations.current = current;

    return AppLocalizations.current;
  }

  String text(String key) {
    final localisedValues = _localisedValues;
    if (localisedValues.containsKey(key)) {
      return localisedValues[key];
    }
    if (_all.isNotEmpty) {
      //logger.e("${_locale.toString()}:'$key' not found");
    }
    return key;
  }

  static String t(String key) {
    if (AppLocalizations.current == null) {
      return key;
    }
    return AppLocalizations.current!.text(key);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    logger.i('will load ${locale.toString()}');
    AppLocalizations? appLocalizations = await AppLocalizations.load(locale);

    return appLocalizations!;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}
