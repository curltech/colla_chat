import 'package:flutter_emoji/flutter_emoji.dart';

class CustomEmojiParser {
  final parser = EmojiParser();

  CustomEmojiParser();

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

final CustomEmojiParser customEmojiParser = CustomEmojiParser();
