import 'package:colla_chat/entity/base.dart';

enum CondType {
  average, //均线价格
  price, //价格
  vol, //成交量
  extreme, //价格极值
}

/// 买卖事件的条件定义
class FilterCond extends StatusEntity {
  String condCode;
  String name;
  String condType;
  String? content;
  String? condParas;
  num? score;
  String? descr;

  FilterCond(this.condCode, this.condType, this.name);

  FilterCond.fromRemoteJson(Map json)
      : condCode = json['cond_code'],
        name = json['name'],
        condType = json['cond_type'],
        content = json['content'],
        condParas = json['cond_paras'],
        score = json['score'],
        descr = json['descr'],
        super.fromJson(json);

  FilterCond.fromJson(Map json)
      : condCode = json['condCode'],
        name = json['name'],
        condType = json['condType'],
        content = json['content'],
        condParas = json['condParas'],
        score = json['score'],
        descr = json['descr'],
        super.fromJson(json);

  Map<String, dynamic> toRemoteJson() {
    var json = super.toJson();
    json.addAll({
      'cond_code': condCode,
      'name': name,
      'cond_type': condType,
      'content': content,
      'cond_paras': condParas,
      'score': score,
      'descr': descr,
    });
    return json;
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'condCode': condCode,
      'name': name,
      'condType': condType,
      'content': content,
      'condParas': condParas,
      'score': score,
      'descr': descr,
    });
    return json;
  }
}
