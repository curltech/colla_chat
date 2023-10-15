import 'package:colla_chat/entity/base.dart';

/// 发生的买卖点事件
class EventCond extends StatusEntity {
  String tsCode;
  String name;
  int tradeDate;
  String eventCode;
  String eventType;
  String eventName;
  String? condCode;
  String? condName;
  String? condAlias;
  String? condContent;
  String? condParas;
  double? condValue;
  double? condResult;
  double? score;
  String? descr;

  EventCond(this.tsCode, this.name, this.tradeDate, this.eventCode,
      this.eventType, this.eventName);

  EventCond.fromJson(Map json)
      : tsCode = json['ts_code'],
        name = json['name'],
        tradeDate = json['trade_date'],
        eventType = json['event_type'],
        eventCode = json['event_code'],
        eventName = json['event_name'],
        condCode = json['cond_code'],
        condName = json['cond_name'],
        condAlias = json['cond_alias'],
        condContent = json['cond_content'],
        condParas = json['cond_paras'],
        condValue = json['cond_value'],
        condResult = json['cond_result'],
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
      'event_type': eventType,
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
