import 'package:colla_chat/widgets/special_text/at_text.dart';
import 'package:colla_chat/widgets/special_text/emoji_text.dart';
import 'package:colla_chat/widgets/special_text/image_text.dart';
import 'package:colla_chat/widgets/special_text/link_text.dart';
import 'package:colla_chat/widgets/special_text/special_color_text.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';

class CustomSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  /// whether show background for @somebody
  final bool showAtBackground;
  final bool showEmojiText;
  final bool showLinkText;
  final bool showSpecialColorText;
  final bool showAtText;
  final bool showImageText;

  CustomSpecialTextSpanBuilder(
      {this.showEmojiText = true,
      this.showLinkText = true,
      this.showSpecialColorText = true,
      this.showAtText = true,
      this.showImageText = false,
      this.showAtBackground = false});

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index}) {
    if (flag == '') {
      return null;
    }

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (showEmojiText && isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start: index! - (EmojiText.flag.length - 1));
    } else if (showSpecialColorText && isStart(flag, SpecialColorText.flag)) {
      return SpecialColorText(textStyle, onTap,
          start: index! - (SpecialColorText.flag.length - 1));
    } else if (showLinkText && isStart(flag, LinkText.flag)) {
      return LinkText(textStyle, onTap,
          start: index! - (LinkText.flag.length - 1));
    } else if (showAtText && isStart(flag, AtText.flag)) {
      return AtText(
        textStyle,
        onTap,
        start: index! - (AtText.flag.length - 1),
        showAtBackground: showAtBackground,
      );
    } else if (showImageText && isStart(flag, ImageText.flag)) {
      return ImageText(textStyle,
          start: index! - (ImageText.flag.length - 1), onTap: onTap);
    }
    return null;
  }

  //build text span to specialText
  @override
  TextSpan build(String data,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    if (data == '') {
      return const TextSpan(text: '');
    }
    final List<InlineSpan> inlineList = <InlineSpan>[];
    if (data.isNotEmpty) {
      //特殊文本
      SpecialText? specialText;
      //字符的堆栈
      String textStack = '';
      //遍历每个字符
      for (int i = 0; i < data.length; i++) {
        final String char = data[i];
        //压入字符堆栈
        textStack += char;
        //特殊字符不为空，则继续添加字符，等待结束
        if (specialText != null) {
          specialText.appendContent(char);
          if (specialText.isEnd(textStack)) {
            inlineList.add(specialText.finishText());
            specialText = null;
            textStack = '';
          }
        } else {
          //特殊字符为空，寻找启示字符形成特殊字符
          specialText = createSpecialText(textStack,
              textStyle: textStyle, onTap: onTap, index: i);
          //特殊字符不为空，启示字符找到，渲染，堆栈清空
          if (specialText != null) {
            if (textStack.length - specialText.startFlag.length >= 0) {
              textStack = textStack.substring(
                  0, textStack.length - specialText.startFlag.length);
              if (textStack.isNotEmpty) {
                inlineList.add(TextSpan(text: textStack, style: textStyle));
              }
            }
            textStack = '';
          }
        }
      }

      //遍历字符串完成
      if (specialText != null) {
        inlineList.add(TextSpan(
            text: specialText.startFlag + specialText.getContent(),
            style: textStyle));
      } else if (textStack.isNotEmpty) {
        inlineList.add(TextSpan(text: textStack, style: textStyle));
      }
    } else {
      inlineList.add(TextSpan(text: data, style: textStyle));
    }

    return TextSpan(children: inlineList, style: textStyle);
  }
}
