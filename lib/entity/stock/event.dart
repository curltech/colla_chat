import 'package:colla_chat/entity/base.dart';

/// 买卖事件的定义
class Event extends StatusEntity {
  String eventCode;
  String eventType;
  String eventName;
  String? condCode;
  String? codeAlias;
  String? condName;
  String? condAlias;
  String? condContent;
  String? condParas;
  double? score;
  String? descr;

  Event(this.eventCode, this.eventType, this.eventName);

  Event.fromJson(Map json)
      : eventCode = json['event_code'],
        eventType = json['event_type'],
        eventName = json['event_name'],
        condCode = json['cond_code'],
        codeAlias = json['code_alias'],
        condName = json['cond_name'],
        condAlias = json['cond_alias'],
        condContent = json['cond_content'],
        condParas = json['cond_paras'],
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
      'cond_code': condCode,
      'code_alias': codeAlias,
      'cond_name': condName,
      'cond_alias': condAlias,
      'cond_content': condContent,
      'cond_paras': condParas,
      'score': score,
      'descr': descr,
    });
    return json;
  }
}
