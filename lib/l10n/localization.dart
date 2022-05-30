import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart';

import '../app.dart';

/// 自己写的，不是gen_l10n创建的，需要从assets目录加载语言包
/// 配置方法：localeResolutionCallback:
//           (Locale locale, Iterable<Locale> supportedLocales) {
//         for (Locale supportedLocale in supportedLocales) {
//           if (supportedLocale.languageCode == locale.languageCode ||
//               supportedLocale.countryCode == locale.countryCode) {
//             return supportedLocale;
//           }
//         }
//         return supportedLocales.first;
//       },
/// 使用的方法是：AppLocalizations.instance.text('page_one')
class AppLocalizations {
  static final AppLocalizations _singleton = AppLocalizations._internal();

  AppLocalizations._internal();

  static AppLocalizations get instance => _singleton;

  late Map<dynamic, dynamic> _localisedValues;

  Future<AppLocalizations> load(Locale locale) async {
    String jsonContent = await rootBundle
        .loadString("assets/locale/localization_${locale.toString()}.json");
    _localisedValues = json.decode(jsonContent);
    return this;
  }

  String text(String key) {
    if (_localisedValues.containsKey(key)) {
      return _localisedValues[key];
    }
    logger.e("$key not found");
    return key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['zh', 'en', 'zh_Hant', 'ja', 'ko'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.instance.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}
