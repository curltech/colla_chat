class DateUtil {
  static String currentDate() {
    var currentDate = DateTime.now().toUtc().toIso8601String();
    return currentDate;
  }

  static formatChinese(String strDate) {
    DateTime t = DateTime.parse(strDate).toLocal();
    strDate = t.toIso8601String();
    int pos = strDate.indexOf('T');
    var strDay = strDate.substring(0, pos);
    var strTime = strDate.substring(pos);
    pos = strTime.indexOf('.');
    strTime = strTime.substring(1, pos);
    DateTime c = DateTime.now().toLocal();
    int diff = c.day - t.day;
    switch (diff) {
      case -3:
        strDay = '大后天';
        break;
      case -2:
        strDay = '后天';
        break;
      case -1:
        strDay = '明天';
        break;
      case 0:
        strDay = '今天';
        break;
      case 1:
        strDay = '昨天';
        break;
      case 2:
        strDay = '前天';
        break;
      case 3:
        strDay = '大前天';
        break;
      case 4:
        strDay = '四天前';
        break;
      default:
        break;
    }
    return '$strDay $strTime';
  }

  static const String full = "yyyy-MM-dd HH:mm:ss";

  static String formatDateV(DateTime dateTime,
      {bool isUtc = true, String format = full}) {
    if (dateTime == null) return "";
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
}
