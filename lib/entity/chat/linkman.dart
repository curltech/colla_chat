import 'package:colla_chat/entity/chat/peer_party.dart';

enum LinkmanStatus {
  none,
  stranger, //陌生人
  bot, //机器人
  chatGPT, //chatGPT聊天机器人
  friend, //好友
  blacklist, //黑名单
  subscript, //订阅
}

/// 联系人，和设备绑定登录成为PeerClient，可能是好友（friend）或者普通联系人
/// 一个linkman对应多个peerclient
/// 意味可以进行普通的文本，语音和视频通话
class Linkman extends PeerParty {
  //用于区分是否是好友，只有好友才能直接聊天
  //非好友的消息需要特别的界面进行处理，非好友的发布的文章也不能直接看到
  //我在对方的状态
  String? myStatus;
  String? linkmanStatus;

  //订阅状态
  String? subscriptStatus;

  Linkman(String peerId, String name) : super(peerId, name);

  Linkman.fromJson(Map json)
      : myStatus = json['myStatus'],
        linkmanStatus = json['linkmanStatus'],
        subscriptStatus = json['subscriptStatus'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'myStatus': myStatus,
      'linkmanStatus': linkmanStatus,
      'subscriptStatus': subscriptStatus
    });
    return json;
  }
}
