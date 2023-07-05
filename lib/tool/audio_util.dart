import 'package:colla_chat/entity/chat/chat_message.dart';

class AudioUtil {
  static String prefixBase64 = 'data:audio/*;base64,';

  static String base64Audio(String img, {ChatMessageMimeType? type}) {
    if (type != null) {
      return prefixBase64.replaceFirst('*', type.name) + img;
    } else {
      return prefixBase64 + img;
    }
  }
}
