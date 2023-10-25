import "package:intl/intl.dart";

/// 格式化数字
/// 支持的掩码 `0` ，`#` ，`.` ， `-` ， `,` ， `E`， `+` ，`%` ， `‰ (\u2030)`， `'` ， `;`
class NumberFormatUtil {
  static String format(double value, String mask, {String? locale}) {
    NumberFormat format = NumberFormat(mask, locale);

    return format.format(value);
  }

  /// 标准的四舍五入2位小数
  static String stdDouble(num value) {
    return value.toStringAsFixed(2);
  }

  /// 标准的百分比
  static String stdPercentage(double value) {
    return format(value, '#0.00%');
  }
}
