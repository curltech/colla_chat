import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/string_util.dart';

class ValidatorUtil {
  static String? emptyValidator(String? value) {
    if (StringUtil.isEmpty(value)) {
      return AppLocalizations.t('Must be not empty');
    }
    return null;
  }

  static String? lengthValidator(String? value,
      {int? minLength, int? maxLength}) {
    if (minLength != null) {
      if (StringUtil.isEmpty(value)) {
        return AppLocalizations.t('Must be not empty');
      }
    }
    int length = value == null ? 0 : value.length;
    if (minLength != null && length < minLength) {
      return '${AppLocalizations.t('Length must more than ')}$minLength';
    }
    if (maxLength != null && length > maxLength) {
      return '${AppLocalizations.t('Length must less than ')}$maxLength';
    }
    return null;
  }

  static String? emailValidator(String? value) {
    if (StringUtil.isEmpty(value)) {
      return AppLocalizations.t('Must be not empty');
    }
    if (value!.length < 5 || !value.contains('@') || !value.contains('.')) {
      return AppLocalizations.t('Must be email');
    }
    return null;
  }

  static String? mobileValidator(String? value) {
    if (StringUtil.isEmpty(value)) {
      return AppLocalizations.t('Must be not empty');
    }
    bool isPhoneNumber = StringUtil.isNumeric(value!);
    if (!isPhoneNumber) {
      return AppLocalizations.t('Must be mobile');
    }
    return null;
  }

  static String? intValidator(String? value, {int? min, int? max}) {
    if (StringUtil.isEmpty(value)) {
      return AppLocalizations.t('Must be not empty');
    }
    int v = int.parse(value!);
    if (min != null && v < min) {
      return AppLocalizations.t('Value must more than ') + '$min';
    }
    if (max != null && v > max) {
      return AppLocalizations.t('Value must less than ') + '$max';
    }
    return null;
  }

  static String? doubleValidator(String? value, {double? min, double? max}) {
    if (StringUtil.isEmpty(value)) {
      return AppLocalizations.t('Must be not empty');
    }
    double v = double.parse(value!);
    if (min != null && v < min) {
      return AppLocalizations.t('Value must more than ') + '$min';
    }
    if (max != null && v > max) {
      return AppLocalizations.t('Value must less than ') + '$max';
    }
    return null;
  }

  static String? dateTimeValidator(String? value,
      {DateTime? min, DateTime? max}) {
    if (min != null) {
      if (StringUtil.isEmpty(value)) {
        return AppLocalizations.t('Must be not empty');
      }
    }
    DateTime? v = value == null ? null : DateTime.parse(value);
    if (v != null && min != null && v.isBefore(min)) {
      return AppLocalizations.t('Value must more than ') + '$min';
    }
    if (v != null && max != null && v.isAfter(max)) {
      return AppLocalizations.t('Value must less than ') + '$max';
    }
    return null;
  }
}
