import 'package:colla_chat/tool/util.dart';

import '../../crypto/util.dart';

class MessageSerializer {
  MessageSerializer();

  static List<int> marshal(dynamic value) {
    String json = JsonUtil.toJsonString(value);

    return CryptoUtil.stringToUtf8(json);
  }

  static Map unmarshal(List<int> data) {
    var json = CryptoUtil.utf8ToString(data);

    return JsonUtil.toJson(json);
  }
}
