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
  int sequenceId = 0;
  List<String>? flags;
  String? direct; //对自己而言，消息是属于发送或者接受
  enough_mail.MailAddress? sender;
  String? senderPeerId; // 消息发送方（作者）peerId
  String? senderClientId;
  List<enough_mail.MailAddress>? senders;
  List<enough_mail.MailAddress>? replyTo;
  String? inReplyTo;
  String? messageId;
  String? sendTime; // 发送时间
  List<enough_mail.MailAddress>? receivers;
  List<enough_mail.MailAddress>? cc;
  List<enough_mail.MailAddress>? bcc;
  String? receiveTime; // 接收时间
  String? receiptTime; // 发送回执时间
  String? readTime; // 阅读时间
  String? subject; // 消息标题
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
        sequenceId = json['sequenceId'],
        inReplyTo = json['inReplyTo'],
        messageId = json['messageId'],
        direct = json['direct'],
        senderPeerId = json['senderPeerId'],
        senderClientId = json['senderClientId'],
        sendTime = json['sendTime'],
        receiveTime = json['receiveTime'],
        receiptTime = json['receiptTime'],
        readTime = json['readTime'],
        subject = json['subject'],
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
      var senders =
          json['senders'] != null ? JsonUtil.toJson(json['senders']) : null;
      if (senders != null && senders is List) {
        this.senders = <enough_mail.MailAddress>[];
        for (var sender in senders) {
          this
              .senders!
              .add(enough_mail.MailAddress.fromJson(JsonUtil.toJson(sender)));
        }
      }
    } catch (e) {
      logger.e('from toJson error:$e');
    }
    try {
      var receivers =
          json['receivers'] != null ? JsonUtil.toJson(json['receivers']) : null;
      if (receivers != null && receivers is List) {
        this.receivers = <enough_mail.MailAddress>[];
        for (var receiver in receivers) {
          this
              .receivers!
              .add(enough_mail.MailAddress.fromJson(JsonUtil.toJson(receiver)));
        }
      }
    } catch (e) {
      logger.e('from toJson error:$e');
    }
    try {
      var cc = json['cc'] != null ? JsonUtil.toJson(json['cc']) : null;
      if (cc != null && cc is List) {
        this.cc = <enough_mail.MailAddress>[];
        for (var c in cc) {
          this.cc!.add(enough_mail.MailAddress.fromJson(JsonUtil.toJson(c)));
        }
      }
    } catch (e) {
      logger.e('cc toJson error:$e');
    }
    try {
      var bcc = json['bcc'] != null ? JsonUtil.toJson(json['bcc']) : null;
      if (bcc != null && bcc is List) {
        this.bcc = <enough_mail.MailAddress>[];
        for (var c in bcc) {
          this.bcc!.add(enough_mail.MailAddress.fromJson(JsonUtil.toJson(c)));
        }
      }
    } catch (e) {
      logger.e('bcc toJson error:$e');
    }
    try {
      var replyTo =
          json['replyTo'] != null ? JsonUtil.toJson(json['replyTo']) : null;
      if (replyTo != null && replyTo is List) {
        this.replyTo = <enough_mail.MailAddress>[];
        for (var c in replyTo) {
          this
              .replyTo!
              .add(enough_mail.MailAddress.fromJson(JsonUtil.toJson(c)));
        }
      }
    } catch (e) {
      logger.e('replyTo toJson error:$e');
    }
    try {
      var sender =
          json['sender'] != null ? JsonUtil.toJson(json['sender']) : null;
      if (sender != null) {
        this.sender = enough_mail.MailAddress.fromJson(JsonUtil.toJson(sender));
      }
    } catch (e) {
      logger.e('sender toJson error:$e');
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
      'sequenceId': sequenceId,
      'inReplyTo': inReplyTo,
      'messageId': messageId,
      'direct': direct,
      'flags': flags == null ? null : JsonUtil.toJsonString(flags),
      'receivers': receivers == null ? null : JsonUtil.toJsonString(receivers),
      'senderPeerId': senderPeerId,
      'senderClientId': senderClientId,
      'sender': sender == null ? null : JsonUtil.toJsonString(sender),
      'senders': senders == null ? null : JsonUtil.toJsonString(senders),
      'cc': senders == null ? null : JsonUtil.toJsonString(cc),
      'bcc': senders == null ? null : JsonUtil.toJsonString(bcc),
      'replyTo': senders == null ? null : JsonUtil.toJsonString(replyTo),
      'sendTime': sendTime,
      'receiveTime': receiveTime,
      'receiptTime': receiptTime,
      'readTime': readTime,
      'subject': subject,
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

  enough_mail.MailAddress? decodeSender() {
    enough_mail.MailAddress? sender = senders?.firstOrNull;
    sender ??= replyTo?.firstOrNull;
    sender ??= this.sender;

    return sender;
  }
}
