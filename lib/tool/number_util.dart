import "dart:math";

import "package:intl/intl.dart";

/// 格式化数字
/// 支持的掩码 `0` ，`#` ，`.` ， `-` ， `,` ， `E`， `+` ，`%` ， `‰ (\u2030)`， `'` ， `;`
class NumberUtil {
  static String format(num value, String mask, {String? locale}) {
    NumberFormat format = NumberFormat(mask, locale);

    return format.format(value);
  }

  /// 标准的四舍五入2位小数
  static String stdDouble(num value) {
    return value.toStringAsFixed(2);
  }

  /// 标准的百分比
  static String stdPercentage(num value) {
    return format(value, '#0.00%');
  }

  /// 枚举索引转换成枚举
  static T? toEnum<T>(Iterable<T> values, int value) {
    List<T> vs = values.toList();
    for (int i = 0; i < vs.length; ++i) {
      if (i == value) {
        return vs[i];
      }
    }

    return null;
  }

  /// 浮点数的G,M,K显示
  static String toGMK<T>(int value) {
    num v = pow(2, 30);
    if (value > v) {
      return '${stdDouble(value / v)}G';
    }
    v = pow(2, 20);
    if (value > v) {
      return '${stdDouble(value / v)}M';
    }
    v = pow(2, 10);
    if (value > v) {
      return '${stdDouble(value / v)}K';
    }

    return '$value';
  }
}
