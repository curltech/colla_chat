import 'package:colla_chat/tool/json_util.dart';
import 'package:dart_quill_delta/src/delta/delta.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class DocumentUtil {
  ///转换成Delta
  static Delta jsonToDelta(List<dynamic> deltaJson) {
    Delta delta = Delta.fromJson(deltaJson);

    return delta;
  }

  ///转换成json
  static String deltaToJson(Delta delta) {
    final deltaJson = delta.toJson();

    return JsonUtil.toJsonString(deltaJson);
  }

  ///转换成html
  static String deltaToHtml(Delta delta) {
    final deltaJson = delta.toJson();
    final converter = QuillDeltaToHtmlConverter(
      List.castFrom(deltaJson),
      ConverterOptions.forEmail(),
    );

    return converter.convert();
  }

  ///转换成html
  static String jsonToHtml(List<dynamic> deltaJson) {
    final converter = QuillDeltaToHtmlConverter(
      List.castFrom(deltaJson),
      ConverterOptions.forEmail(),
    );

    return converter.convert();
  }
}
