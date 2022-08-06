import 'package:flutter_emoji/flutter_emoji.dart';

///未完成
class TwEmojiParser {
  final parser = EmojiParser();

  TwEmojiParser();

  Emoji createEmoji(String name, String code) {
    return Emoji(name, code);
  }

  Emoji get(String name) {
    return parser.get(name);
  }

  bool hasName(String name) {
    return parser.hasName(name);
  }

  List<String> parseEmojis(String text) {
    return parser.parseEmojis(text);
  }

  String emojify(String text) {
    return parser.emojify(text);
  }

  String unemojify(String text) {
    return parser.unemojify(text);
  }
}

final TwEmojiParser twEmojiParser = TwEmojiParser();
