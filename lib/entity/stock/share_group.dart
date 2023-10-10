import 'package:colla_chat/entity/base.dart';

class ShareGroup extends StatusEntity {
  String? subscription; //TS代码
  String? groupName; // str 分组名

  ShareGroup();

  ShareGroup.fromJson(Map json)
      : subscription = json['subscription'],
        groupName = json['groupName'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'subscription': subscription,
      'groupName': groupName,
    });
    return json;
  }
}
