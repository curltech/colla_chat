import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

///#开头，#结尾的特殊字符串，link标记，用于URI
class LinkText extends SpecialText {
  LinkText(TextStyle? textStyle, SpecialTextGestureTapCallback? onTap,
      {this.start})
      : super(flag, flag, textStyle, onTap: onTap);
  static const String flag = '#';
  final int? start;

  @override
  bool isEnd(String value) {
    bool end = false;
    end = value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('mailto:') ||
        value.startsWith('tel:') ||
        value.startsWith('sms:') ||
        value.startsWith('file:');
    if (end && super.isEnd(value)) {
      return true;
    }
    final int index = value.indexOf('@');
    final int index1 = value.indexOf('.');
    end = index > 0 && index1 > index && super.isEnd(value);

    return end;
  }

  @override
  InlineSpan finishText() {
    final String text = getContent();

    return SpecialTextSpan(
        text: text,
        actualText: toString(),
        start: start!,

        ///caret can move into special text
        deleteAll: true,
        style: textStyle?.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) {
              onTap!(toString());
            }
          });
  }
}
