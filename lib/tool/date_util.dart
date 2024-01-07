import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

class DateUtil {
  ///获取当前Utc时间
  static DateTime currentDateTime() {
    var currentDate = DateTime.now().toUtc();
    return currentDate;
  }

  ///获取当前时间的ISO字符串
  static String currentDate() {
    var currentDate = DateTime.now().toUtc().toIso8601String();
    return currentDate;
  }

  static String maxDate() {
    return '9999-12-31T11:59:59.999Z';
  }

  ///将时间字符串格式化成易读的文字
  static String formatEasyRead(String strDate, {bool withYear = true}) {
    DateTime t = DateTime.parse(strDate).toLocal();
    strDate = t.toIso8601String();
    int pos = strDate.indexOf('T');
    int start = 0;
    if (!withYear) {
      start = 5;
    }
    String strDay = strDate.substring(start, pos);
    String strTime = strDate.substring(pos + 1);
    pos = strTime.lastIndexOf(':');
    strTime = strTime.substring(0, pos);
    DateTime c = DateTime.now().toLocal();
    Duration diff = c.difference(t);
    switch (diff.inDays) {
      case -3:
        strDay = AppLocalizations.t('3 DFN.');
        break;
      case -2:
        strDay = AppLocalizations.t('Overmorrow');
        break;
      case -1:
        strDay = AppLocalizations.t('Tomorrow');
        break;
      case 0:
        strDay = AppLocalizations.t('Today');
        break;
      case 1:
        strDay = AppLocalizations.t('Yesterday');
        break;
      case 2:
        strDay = AppLocalizations.t('Ereyesterday');
        break;
      case 3:
        strDay = AppLocalizations.t('3 DA.');
        break;
      case 4:
        strDay = AppLocalizations.t('4 DA.');
        break;
      default:
        break;
    }
    return '$strDay $strTime';
  }

  static const String full = "yyyy-MM-dd HH:mm:ss";

  ///将时间格式化成字符串
  static String formatDate(DateTime dateTime,
      {bool isUtc = true, String format = full}) {
    format = format ?? full;
    if (format.contains("yy")) {
      String year = dateTime.year.toString();
      if (format.contains("yyyy")) {
        format = format.replaceAll("yyyy", year);
      } else {
        format = format.replaceAll(
            "yy", year.substring(year.length - 2, year.length));
      }
    }

    format = _comFormat(dateTime.month, format, 'M', 'MM');
    format = _comFormat(dateTime.day, format, 'd', 'dd');
    format = _comFormat(dateTime.hour, format, 'H', 'HH');
    format = _comFormat(dateTime.minute, format, 'm', 'mm');
    format = _comFormat(dateTime.second, format, 's', 'ss');
    format = _comFormat(dateTime.millisecond, format, 'S', 'SSS');

    return format;
  }

  static String _comFormat(
      int value, String format, String single, String full) {
    if (format.contains(single)) {
      if (format.contains(full)) {
        format =
            format.replaceAll(full, value < 10 ? '0$value' : value.toString());
      } else {
        format = format.replaceAll(single, value.toString());
      }
    }
    return format;
  }

  static int formatDateInt(DateTime dateTime) {
    return dateTime.year * 10000 + dateTime.month * 100 + dateTime.day;
  }

  static String formatDateQuarter(DateTime dateTime) {
    int month = (dateTime.month / 3).floor();
    if (month == 0) {
      return '${dateTime.year - 1}Q4';
    } else {
      return '${dateTime.year}Q$month';
    }
  }

  static DateTime toDateTime(String formattedString) {
    return DateTime.parse(formattedString);
  }

  static TimeOfDay toTime(String formattedString) {
    var hour = formattedString.substring(0, 2);
    var minute = formattedString.substring(3, 2);
    return TimeOfDay(hour: int.parse(hour), minute: int.parse(minute));
  }

  static String toLocal(String formattedString) {
    var dateTime = DateTime.parse(formattedString);
    return dateTime.toLocal().toIso8601String();
  }

  static String toUtc(String formattedString) {
    var dateTime = DateTime.parse(formattedString);
    return dateTime.toUtc().toIso8601String();
  }
}
