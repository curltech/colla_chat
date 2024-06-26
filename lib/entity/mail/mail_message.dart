import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/message_attachment.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;

// 邮件消息
class MailMessage extends StatusEntity {
  String? emailAddress;
  String? mailboxName;
  int uid = 0;
  int guid = 0;
  List<String>? flags;
  String? direct; //对自己而言，消息是属于发送或者接受
  String? senderPeerId; // 消息发送方（作者）peerId
  String? senderClientId;
  String? senderType;
  String? senderName;
  List<enough_mail.MailAddress>? senderAddress;
  String? sendTime; // 发送时间
  String? receiverName;
  List<enough_mail.MailAddress>? receiverAddress;
  String? receiveTime; // 接收时间
  String? receiptTime; // 发送回执时间
  String? readTime; // 阅读时间
  String? title; // 消息标题
  String? thumbnail; // 预览缩略图（base64图片，适用需预览的content，如笔记、联系人名片）
  String? content; // 消息内容
  String? receiptType; // 回执的内容
  int deleteTime = 0; // 阅读后的删除时间，秒数，0表示不删除
  String? parentMessageId; //引用的消息编号
  bool needReceipt = false;
  bool needReadReceipt = false;

  //消息附件
  List<MessageAttachment> attaches = [];

  MailMessage();

  MailMessage.fromJson(Map json)
      : emailAddress = json['emailAddress'],
        mailboxName = json['mailboxName'],
        uid = json['uid'],
        guid = json['guid'],
        direct = json['direct'],
        receiverName = json['receiverName'],
        senderPeerId = json['senderPeerId'],
        senderClientId = json['senderClientId'],
        senderName = json['senderName'],
        senderType = json['senderType'],
        sendTime = json['sendTime'],
        receiveTime = json['receiveTime'],
        receiptTime = json['receiptTime'],
        readTime = json['readTime'],
        title = json['title'],
        receiptType = json['receiptType'],
        thumbnail = json['thumbnail'],
        content = json['content'],
        deleteTime = json['deleteTime'],
        parentMessageId = json['parentMessageId'],
        needReceipt = json['needReceipt'] == true || json['needReceipt'] == 1
            ? true
            : false,
        needReadReceipt =
            json['needReadReceipt'] == true || json['needReadReceipt'] == 1
                ? true
                : false,
        super.fromJson(json) {
    try {
      var flags = json['flags'] != null ? JsonUtil.toJson(json['flags']) : null;
      if (flags != null && flags is List) {
        this.flags = <String>[];
        for (var flag in flags) {
          this.flags!.add(flag.toString());
        }
      }
    } catch (e) {
      logger.e('flags toJson error:$e');
    }
    try {
      var receiverAddress = json['receiverAddress'] != null
          ? JsonUtil.toJson(json['receiverAddress'])
          : null;
      if (receiverAddress != null && receiverAddress is List) {
        this.receiverAddress = <enough_mail.MailAddress>[];
        for (var receiverAddr in receiverAddress) {
          this.receiverAddress!.add(
              enough_mail.MailAddress.fromJson(JsonUtil.toJson(receiverAddr)));
        }
      }
    } catch (e) {
      logger.e('receiverAddress toJson error:$e');
    }
    try {
      var senderAddress = json['senderAddress'] != null
          ? JsonUtil.toJson(json['senderAddress'])
          : null;
      if (senderAddress != null && senderAddress is List) {
        this.senderAddress = <enough_mail.MailAddress>[];
        for (var senderAddr in senderAddress) {
          this.senderAddress!.add(
              enough_mail.MailAddress.fromJson(JsonUtil.toJson(senderAddr)));
        }
      }
    } catch (e) {
      logger.e('senderAddress toJson error:$e');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'emailAddress': emailAddress,
      'mailboxName': mailboxName,
      'uid': uid,
      'guid': guid,
      'direct': direct,
      'flags': flags == null ? null : JsonUtil.toJsonString(flags),
      'receiverName': receiverName,
      'receiverAddress': receiverAddress == null
          ? null
          : JsonUtil.toJsonString(receiverAddress),
      'senderPeerId': senderPeerId,
      'senderClientId': senderClientId,
      'senderType': senderType,
      'senderName': senderName,
      'senderAddress':
          senderAddress == null ? null : JsonUtil.toJsonString(senderAddress),
      'sendTime': sendTime,
      'receiveTime': receiveTime,
      'receiptTime': receiptTime,
      'readTime': readTime,
      'title': title,
      'receiptType': receiptType,
      'thumbnail': thumbnail,
      'content': content,
      'deleteTime': deleteTime,
      'parentMessageId': parentMessageId,
      'needReceipt': needReceipt,
      'needReadReceipt': needReadReceipt,
    });
    return json;
  }

  ///是否是自己发送的邮件
  bool get isMyself {
    bool isMyself = false;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      isMyself = true;
    }
    return isMyself;
  }
}
