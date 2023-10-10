import 'package:colla_chat/entity/base.dart';

class ShareGroup extends StatusEntity {
  String? tsCode; //TS代码
  String? groupName; // str 分组名

  ShareGroup();

  ShareGroup.fromJson(Map json)
      : tsCode = json['tsCode'],
        groupName = json['groupName'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'tsCode': tsCode,
      'groupName': groupName,
    });
    return json;
  }
}
