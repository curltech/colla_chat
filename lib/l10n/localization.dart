import 'dart:async';
import 'dart:convert';

import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 自己写的，不是gen_l10n创建的，需要从assets目录加载语言包
/// 使用的方法是：AppLocalizations.instance.text('page_one')
class AppLocalizations {
  static AppLocalizations _current =
      AppLocalizations(const Locale('zh', 'CN'), {});
  static final Map<Locale, AppLocalizations> _all = {};

  final Map<dynamic, dynamic> _localisedValues;
  final Locale _locale;

  AppLocalizations(this._locale, this._localisedValues);

  static AppLocalizations get instance {
    return _current;
  }

  static set instance(AppLocalizations appLocalizations) {
    _current = appLocalizations;
  }

  static Future<AppLocalizations> load(Locale locale) async {
    Map<Locale, AppLocalizations> all = AppLocalizations._all;
    AppLocalizations? current = all[locale];
    if (current == null) {
      String jsonContent = await rootBundle
          .loadString("assets/locale/localization_${locale.toString()}.json");
      var localisedValues = json.decode(jsonContent);
      current = AppLocalizations(locale, localisedValues);
      all[locale] = current;
    }
    AppLocalizations.instance = current;

    return AppLocalizations.instance;
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

  static t(String key) {
    return AppLocalizations.instance.text(key);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh_CN', 'en_US', 'zh_TW', 'ja_JP', 'ko_KR']
        .contains(locale.toString());
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    logger.i('will load ${locale.toString()}');

    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}
