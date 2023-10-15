import 'package:colla_chat/entity/base.dart';

/// 买卖事件的定义
class Event extends StatusEntity {
  String eventCode;
  String? eventType;
  String eventName;
  String? content;
  String? contentParas;
  double? score;
  String? descr;

  Event(this.eventCode, this.eventName);

  Event.fromJson(Map json)
      : eventCode = json['event_code'],
        eventType = json['event_type'],
        eventName = json['event_name'],
        content = json['content'],
        contentParas = json['content_paras'],
        score = json['score'],
        descr = json['descr'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'event_code': eventCode,
      'event_type': eventType,
      'event_name': eventName,
      'content': content,
      'content_paras': contentParas,
      'score': score,
      'descr': descr,
    });
    return json;
  }
}
