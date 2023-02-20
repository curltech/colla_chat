import 'package:colla_chat/l10n/localization.dart';

class DateUtil {
  ///获取当前时间的ISO字符串
  static DateTime currentDateTime() {
    var currentDate = DateTime.now().toUtc();
    return currentDate;
  }

  ///获取当前时间的ISO字符串
  static String currentDate() {
    var currentDate = DateTime.now().toUtc().toIso8601String();
    return currentDate;
  }

  ///将时间字符串格式化成易读的文字
  static String formatEasyRead(String strDate) {
    DateTime t = DateTime.parse(strDate).toLocal();
    strDate = t.toIso8601String();
    int pos = strDate.indexOf('T');
    var strDay = strDate.substring(0, pos);
    var strTime = strDate.substring(pos + 1);
    pos = strTime.lastIndexOf(':');
    strTime = strTime.substring(0, pos);
    DateTime c = DateTime.now().toLocal();
    int diff = c.day - t.day;
    switch (diff) {
      case -3:
        strDay = AppLocalizations.t('Three days from now');
        break;
      case -2:
        strDay = AppLocalizations.t('Day after tomorrow');
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
        strDay = AppLocalizations.t('Day before yesterday');
        break;
      case 3:
        strDay = AppLocalizations.t('Three days ago');
        break;
      case 4:
        strDay = AppLocalizations.t('Four days ago');
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

  static DateTime toDateTime(String formattedString) {
    return DateTime.parse(formattedString);
  }
}
