import 'package:flutter/services.dart';

class ClipboardUtil {
  /// 拷贝文本到剪切板
  static Future<void> copy(String text) async {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      return;
    } else {
      throw ('Please enter a string');
    }
  }

  /// 从剪切板返回字符串
  static Future<String> paste() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    return data?.text?.toString() ?? "";
  }
}
