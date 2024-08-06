import 'package:unicode_emojis/unicode_emojis.dart';

class EmojiUtil {
  static final Map<Category, List<Emoji>> _emojis = {};

  static Map<Category, List<Emoji>> get emojis {
    if (_emojis.isEmpty) {
      for (var emoji in UnicodeEmojis.allEmojis) {
        if (!_emojis.containsKey(emoji.category)) {
          _emojis[emoji.category] = [];
        }
        _emojis[emoji.category]!.add(emoji);
      }
    }
    return _emojis;
  }

  static List<Emoji> search(String key) {
    final List<Emoji> emojis = UnicodeEmojis.search(key);

    return emojis;
  }

  static Map<String, List<Emoji>> index(String key) {
    final Map<String, List<Emoji>> emojis = UnicodeEmojis.index;

    return emojis;
  }
}
