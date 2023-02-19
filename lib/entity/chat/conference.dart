import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/peer_party.dart';

class Conference extends StatusEntity {
  String conferenceId; // 会议编号，也是房间号，也是邀请消息号
  String? name;
  String? title;
  String? conferenceOwnerPeerId; // 发起人
  String? password; // 密码
  bool linkman = false; // 是否好友才能参加
  bool contact = false; // 是否在地址本才能参加
  String? startDate; // 开始时间
  String? endDate; // 结束时间
  bool notification = true; // 自动发送会议通知
  bool mute = false; // 自动静音
  bool video = true; // 是否视频
  bool wait = true; // 自动等待
  bool advance = true; // 参会者可提前加入
  int upperNumber = 300; // 参会人数上限
  List<String> participants; // 参与人peerId的集合

  Conference(this.conferenceId,
      {this.name,
      this.conferenceOwnerPeerId,
      this.title,
      this.participants = const <String>[]});

  Conference.fromJson(Map json)
      : conferenceId = json['conferenceId'],
        name = json['name'],
        title = json['title'],
        conferenceOwnerPeerId = json['conferenceOwnerPeerId'],
        password = json['password'],
        startDate = json['startDate'],
        endDate = json['endDate'],
        linkman =
            json['linkman'] == true || json['linkman'] == 1 ? true : false,
        contact =
            json['contact'] == true || json['contact'] == 1 ? true : false,
        notification = json['notification'] == true || json['notification'] == 1
            ? true
            : false,
        mute = json['mute'] == true || json['mute'] == 1 ? true : false,
        video = json['video'] == true || json['video'] == 1 ? true : false,
        wait = json['wait'] == true || json['wait'] == 1 ? true : false,
        advance =
            json['advance'] == true || json['advance'] == 1 ? true : false,
        upperNumber = json['upperNumber'],
        participants = json['participants'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'conferenceId': conferenceId,
      'name': name,
      'title': title,
      'conferenceOwnerPeerId': conferenceOwnerPeerId,
      'password': password,
      'startDate': startDate,
      'endDate': endDate,
      'linkman': linkman,
      'contact': contact,
      'notification': notification,
      'mute': mute,
      'advance': advance,
      'video': video,
      'upperNumber': upperNumber,
    });
    return json;
  }
}
