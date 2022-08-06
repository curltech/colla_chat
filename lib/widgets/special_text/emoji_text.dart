import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

const String emojiFilePath = "assets/images/emoji";
const int emojiCount = 112;

///emoji/image text
class EmojiText extends SpecialText {
  static const String flag = "[";
  final int start;

  EmojiText(TextStyle? textStyle, {required this.start})
      : super(EmojiText.flag, "]", textStyle);

  @override
  InlineSpan finishText() {
    var key = toString();
    if (emojiTextCollection.emojiMap.containsKey(key)) {
      //fontsize id define image height
      //size = 30.0/26.0 * fontSize
      const double size = 20.0;

      ///fontSize 26 and text height =30.0
      //final double fontSize = 26.0;
      String emoji = emojiTextCollection.emojiMap[key] ?? '';
      return ImageSpan(AssetImage(emoji),
          actualText: key,
          imageWidth: size,
          imageHeight: size,
          start: start,
          fit: BoxFit.fill,
          margin: const EdgeInsets.only(left: 2.0, right: 2.0));
    }

    return TextSpan(text: toString(), style: textStyle);
  }
}

///emoji文本的集合
class EmojiTextCollection {
  final Map<String, String> emojiMap = <String, String>{};

  EmojiTextCollection() {
    for (int i = 1; i < emojiCount; i++) {
      emojiMap["[$i]"] = "$emojiFilePath/sg$i.png";
    }
  }
}

final EmojiTextCollection emojiTextCollection = EmojiTextCollection();
