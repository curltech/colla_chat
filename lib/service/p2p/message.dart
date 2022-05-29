import 'dart:typed_data';
import 'package:colla_chat/tool/util.dart';
import '../../crypto/util.dart';

class MessageSerializer {
  MessageSerializer();

  static Uint8List marshal(dynamic value) {
    String json = '${JsonUtil.toJsonString(value)}\n';

    return CryptoUtil.strToUint8List(json);
  }

  static Map unmarshal(List<int> data) {
    var json = CryptoUtil.uint8ListToStr(data);

    return JsonUtil.toMap(json);
  }
}
