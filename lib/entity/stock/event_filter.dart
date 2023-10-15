import 'package:colla_chat/entity/base.dart';

/// 买卖点事件的条件组合
class EventFilter extends StatusEntity {
  String eventCode;
  String eventName;
  String condCode;
  String? codeAlias;
  String condName;
  String? condAlias;
  String condContent;
  String? condParas;
  num? score;
  String? descr;

  EventFilter(this.condCode, this.condName, this.condContent, this.eventCode,
      this.eventName);

  EventFilter.fromJson(Map json)
      : eventCode = json['event_code'],
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
