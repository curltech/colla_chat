import 'package:colla_chat/entity/base.dart';

/// 附件（单聊/群聊/频道/收藏）,当chatmessage的content很大的时候存储在这里
class MessageAttachment extends BaseEntity {
  String? messageId; // 消息的唯一id标识
  String? title;
  String?
      content; // 消息内容（基于mime+自定义标识区分内容类型，如：application/audio/image/message/text/video/x-word, contact联系人名片, groupChat群聊, channel频道）

  MessageAttachment();

  MessageAttachment.fromJson(super.json)
      : messageId = json['messageId'],
        title = json['title'],
        content = json['content'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'messageId': messageId,
      'title': title,
      'content': content,
    });
    return json;
  }
}
