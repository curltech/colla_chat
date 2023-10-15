import 'package:colla_chat/entity/base.dart';

/// 买卖事件的条件定义
class FilterCond extends StatusEntity {
  String condCode;
  String name;
  String condType;
  String? content;
  String? condParas;
  double? score;
  String? descr;

  FilterCond(this.condCode, this.condType, this.name);

  FilterCond.fromJson(Map json)
      : condCode = json['cond_code'],
        name = json['name'],
        condType = json['cond_type'],
        content = json['content'],
        condParas = json['cond_paras'],
        score = json['score'],
        descr = json['descr'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
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
}
