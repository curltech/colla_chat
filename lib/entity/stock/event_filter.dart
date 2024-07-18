import 'package:colla_chat/entity/base.dart';

/// 买卖点事件的条件
class EventFilter extends StatusEntity {
  String eventCode;
  String eventName;
  String? condContent;
  String? condParas;
  String? descr;

  EventFilter(this.eventCode, this.eventName);

  EventFilter.fromJson(super.json)
      : eventCode = json['eventCode'],
        eventName = json['eventName'],
        condContent = json['condContent'],
        condParas = json['condParas'],
        descr = json['descr'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'eventCode': eventCode,
      'eventName': eventName,
      'condContent': condContent,
      'condParas': condParas,
      'descr': descr,
    });
    return json;
  }
}
