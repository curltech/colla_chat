import 'package:colla_chat/entity/chat/peer_party.dart';

/// 手机联系人,从移动设备中读取出来的
class Contact extends PeerParty {
  String? formattedName;
  bool linkman = false;

  Contact(String peerId, String name) : super(peerId, name);

  Contact.fromJson(Map json)
      : formattedName = json['formattedName'],
        linkman =
            json['linkman'] == true || json['linkman'] == 1 ? true : false,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'formattedName': formattedName,
      'trustLevel': trustLevel,
      'linkman': linkman,
    });
    return json;
  }
}
