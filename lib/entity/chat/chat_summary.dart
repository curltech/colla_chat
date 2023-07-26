import 'package:colla_chat/entity/base.dart';

/// party的最新消息汇总
/// 每次有新消息到达，则更新，每个party一条记录
class ChatSummary extends StatusEntity {
  // 聊天信息汇总没有clientId，每一条汇总对应一个peerId和多个clientId
  String? peerId; // 接收者或者发送者的联系人或群 //String? clientId;
  String? partyType; // 接收者或者发送者类型
  String? subPartyType; //接收者或者发送者子类型，比如群的子类型
  String? messageId; // 最新的消息Id
  String? messageType; // 最新的消息类型
  String? subMessageType; // 最新的消息子类型
  String? name; // 接收者或者发送者联系人或者群的名称
  String? title; // 标题
  String? receiptContent; // 回执内容
  String? thumbnail; // 预览缩略图（base64图片，适用需预览的content，如笔记、联系人名片）
  String? content;
  String? contentType;
  bool needCompress = false;
  bool needEncrypt = true;
  String? sendReceiveTime; // 发送接收时间
  int unreadNumber = 0;
  String? payloadHash;
  String? payloadKey;

  ChatSummary();

  ChatSummary.fromJson(Map json)
      : peerId = json['peerId'],
        //clientId = json['clientId'],
        partyType = json['partyType'],
        subPartyType = json['subPartyType'],
        messageId = json['messageId'],
        messageType = json['messageType'],
        subMessageType = json['subMessageType'],
        name = json['name'],
        title = json['title'],
        receiptContent = json['receiptContent'],
        thumbnail = json['thumbnail'],
        content = json['content'],
        contentType = json['contentType'],
        needCompress = json['needEncrypt'] == null ||
                json['needCompress'] == true ||
                json['needCompress'] == 1
            ? true
            : false,
        needEncrypt = json['needEncrypt'] == null ||
                json['needEncrypt'] == true ||
                json['needEncrypt'] == 1
            ? true
            : false,
        sendReceiveTime = json['sendReceiveTime'],
        unreadNumber = json['unreadNumber'],
        payloadKey = json['payloadKey'],
        payloadHash = json['payloadHash'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId, //'clientId': clientId,
      'partyType': partyType,
      'subPartyType': subPartyType,
      'messageId': messageId,
      'messageType': messageType,
      'subMessageType': subMessageType,
      'name': name,
      'title': title,
      'receiptContent': receiptContent,
      'thumbnail': thumbnail,
      'content': content,
      'contentType': contentType,
      'needCompress': needCompress,
      'needEncrypt': needEncrypt,
      'sendReceiveTime': sendReceiveTime,
      'unreadNumber': unreadNumber,
      'payloadKey': payloadKey,
      'payloadHash': payloadHash,
    });
    return json;
  }
}
