import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';

class StringUtil {
  // 是否是空字符串
  static bool isEmpty(String? str) {
    if (str == null || str.isEmpty) {
      return true;
    }
    return false;
  }

  // 是否不是空字符串
  static bool isNotEmpty(String? str) {
    if (str != null && str.isNotEmpty) {
      return true;
    }
    return false;
  }

  // 首字符小写
  static String? lowerFirst(String? str) {
    if (str != null && str.isNotEmpty) {
      return str[0].toLowerCase() + str.substring(1);
    }
    return str;
  }

  // 首字符小写
  static String? upperFirst(String? str) {
    if (str != null && str.isNotEmpty) {
      return str[0].toUpperCase() + str.substring(1);
    }
    return str;
  }

  static dynamic toObject(String str, DataType dataType) {
    if (dataType == DataType.string) {
      return str;
    }
    if (StringUtil.isEmpty(str)) {
      return null;
    }
    dynamic value;
    switch (dataType) {
      case DataType.int:
        value = int.parse(str);
        break;
      case DataType.double:
        value = double.parse(str);
        break;
      case DataType.date:
        value = DateTime.parse(str);
        break;
      case DataType.datetime:
        value = DateTime.parse(str);
        break;
      case DataType.time:
        value = DateUtil.toTime(str);
        break;
    }
    return value;
  }

  /// 匹配
  static bool matches(String regex, String input) {
    if (input.isEmpty) return false;
    return RegExp(regex).hasMatch(input);
  }

  /// 纯数字 ^[0-9]*$
  static bool pureDigitCharacters(String input) {
    const String regex = "^[0-9]*\$";
    return matches(regex, input);
  }

  static bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  ///string转枚举类型
  static T? enumFromString<T>(Iterable<T> values, String? value,
      {T? defaultType}) {
    if (value == null) {
      return defaultType;
    }
    try {
      return values
          .firstWhere((type) => type.toString().split('.').last == value);
    } catch (e) {
      logger.e('enum exception:$e');
    }

    return defaultType;
  }
}
