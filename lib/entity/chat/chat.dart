import '../base.dart';

/// 聊天的定义

var period = 300; //5m

enum ContentType {
  rich, // 根据场景包含类型不同，如非系统类型、可搜索类型等
  image,
  text,
  file,
  audio,
  video,
  card,
  note,
  channel,
  article,
  chat,
  link,
  voice,
  position,
  audioInvitation,
  audioHistory,
  videoHistory,
  videoInvitation,
  callJoinRequest,
  event,
  time,
  reject,
  close,
  busy
}

// 消息类型（messageType）,system消息不在聊天界面显示
enum ChatMessageType {
  email,
  //聊天消息，在聊天界面上显示的消息
  chat,
  //系统消息，不在聊天界面上显示的消息
  system
}

enum ChatSubMessageType {
  addLinkman, // 新增联系人请求
  addLinkmanReply, // 新增联系人请求的回复
  syncLinkmanInfo, // 联系人基本信息同步
  removeLinkman, // 从好友中删除
  removeLinkmanReceipt, // 删除好友通知回复
  blackLinkman, // 加入黑名单
  blackLinkmanReceipt, // 加入黑名单通知回复
  unblackLinkman, // 从黑名单中移除
  unblackLinkmanReceipt, // 移除黑名单通知回复
  // 联系人请求
  addGroup, // 新增群聊请求
  addGroupReceipt, // 新增群聊请求接收回复
  dismissGroup, // 解散群聊请求
  dismissGroupReceipt, // 解散群聊请求接收回复
  modifyGroup, // 修改群聊请求
  modifyGroupReceipt, // 修改群聊请求接收回复
  modifyGroupOwner, // 修改群主请求
  modifyGroupOwnerReceipt, // 修改群主请求接收回复
  addGroupMember, // 新增群聊成员请求
  addGroupMemberReceipt, // 新增群聊成员请求接收回复
  removeGroupMember, // 删除群聊成员请求
  removeGroupMemberReceipt, // 删除群聊成员请求接收回复
  // 聊天
  chat, // 联系人发送聊天消息
  chatSystem, // 系统预定义聊天消息，如群聊动态通知
  videoChat,
  audioChat,
  deleteChat,
  chatReceipt, // 接收回复
  groupFile,
  //system消息
  signal, //webrtc signal消息，一般用于重新协商的情况
  preKeyBundle, //signal加解密
}

enum MessageStatus {
  unsent, //未发送成功
  send, //发了，不知是否成功
  sent, //发送成功
  received, //已接收
  read, //已读
  accepted,
  rejected,
  ignored,
  deleted, //删除
}

///好友，群，潜在，联系人，频道，房间
enum PartyType { linkman, group, peerClient, contact, channel, room }

enum ChatDirect { receive, send }

enum TransportType { websocket, webrtc, email, sms }

// 消息，泛指一切社交复合文档，最简单的是一句话，最复杂可以是非常复杂的混合文本，图片，视频的文档
class ChatMessage extends StatusEntity {
  String ownerPeerId; // 区分本地不同peerClient属主
  String? transportType; // 包括：websocket,webrtc,mail,sms
  String? messageId; // 消息的唯一id标识
  String messageType = ''; // 消息类型（对应channel消息类型）
  String? subMessageType;
  String? direct; //对自己而言，消息是属于发送或者接受

  ///当发送者向群，自己作为群成员或者我发消息，填写发送者的信息
  ///此时我属于接收方，direct为接收
  ///此时receiver的信息填写群的信息，如果是发送给我，可以不填写
  String? senderPeerId; // 消息发送方（作者）peerId
  String? senderClientId;
  String? senderType;
  String? senderName;
  String? senderAddress;
  String? sendTime; // 发送时间
  ///如果我作为发送者向别人或者群发送消息，此时direct为send
  ///receiver填写别人或者群的信息
  ///此时发送者的信息可以不填写
  String? receiverPeerId; // 目标的唯一id标识（单聊对应linkman-peerId，群聊对应group-peerId）
  String? receiverClientId;
  String? receiverType; // 包括：Linkman（单聊）, Group（群聊）,Channel,
  String? receiverName;
  String? groupPeerId; // 目标的唯一id标识（单聊对应linkman-peerId，群聊对应group-peerId）
  String? groupName;
  String? receiverAddress;
  String? receiveTime; // 接收时间
  String? receiptTime; // 发送回执时间
  String? readTime; // 阅读时间
  String? title; // 消息标题
  String? thumbBody; // 预览内容（适用需预览的content，如笔记、转发聊天）
  String? thumbnail; // 预览缩略图（base64图片，适用需预览的content，如笔记、联系人名片）
  String? content; // 消息内容
  String? contentType;
  String? deleteTime;
  bool needCompress = true;
  bool needEncrypt = true;
  bool needReceipt = false;
  bool needReadReceipt = false;

  /// primary peer的publicKey
  String? primaryPeerId;
  String? primaryPublicKey;
  String? primaryAddress;
  String? ephemeralPublicKey;
  String? payloadHash;
  String? payloadSignature;
  String? payloadKey;

  //消息附件
  List<MessageAttachment> attaches = [];

  //本消息是合并消息
  List<ChatMessage> messages = [];

  ChatMessage(this.ownerPeerId);

  ChatMessage.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        receiverType = json['receiverType'],
        transportType = json['transportType'],
        direct = json['direct'],
        receiverPeerId = json['receiverPeerId'],
        receiverClientId = json['receiverClientId'],
        receiverName = json['receiverName'],
        groupPeerId = json['groupPeerId'],
        groupName = json['groupName'],
        receiverAddress = json['receiverAddress'],
        messageId = json['messageId'],
        messageType = json['messageType'],
        subMessageType = json['subMessageType'],
        senderPeerId = json['senderPeerId'],
        senderClientId = json['senderClientId'],
        senderName = json['senderName'],
        senderAddress = json['senderAddress'],
        senderType = json['senderType'],
        sendTime = json['sendTime'],
        receiveTime = json['receiveTime'],
        receiptTime = json['receiptTime'],
        readTime = json['readTime'],
        title = json['title'],
        thumbBody = json['thumbBody'],
        thumbnail = json['thumbnail'],
        content = json['content'],
        contentType = json['contentType'],
        deleteTime = json['deleteTime'],
        payloadHash = json['payloadHash'],
        payloadSignature = json['payloadSignature'],
        primaryPeerId = json['primaryPeerId'],
        primaryPublicKey = json['primaryPublicKey'],
        primaryAddress = json['primaryAddress'],
        payloadKey = json['payloadKey'],
        ephemeralPublicKey = json['ephemeralPublicKey'],
        needCompress = json['needCompress'] == true || json['needCompress'] == 1
            ? true
            : false,
        needEncrypt = json['needEncrypt'] == true || json['needEncrypt'] == 1
            ? true
            : false,
        needReceipt = json['needReceipt'] == true || json['needReceipt'] == 1
            ? true
            : false,
        needReadReceipt =
            json['needReadReceipt'] == true || json['needReadReceipt'] == 1
                ? true
                : false,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'transportType': transportType,
      'direct': direct,
      'receiverType': receiverType,
      'receiverPeerId': receiverPeerId,
      'receiverClientId': receiverClientId,
      'receiverName': receiverName,
      'groupPeerId': groupPeerId,
      'groupName': groupName,
      'receiverAddress': receiverAddress,
      'messageId': messageId,
      'messageType': messageType,
      'subMessageType': subMessageType,
      'senderPeerId': senderPeerId,
      'senderClientId': senderClientId,
      'senderType': senderType,
      'senderName': senderName,
      'senderAddress': senderAddress,
      'sendTime': sendTime,
      'receiveTime': receiveTime,
      'receiptTime': receiptTime,
      'readTime': readTime,
      'title': title,
      'thumbBody': thumbBody,
      'thumbnail': thumbnail,
      'content': content,
      'contentType': contentType,
      'deleteTime': deleteTime,
      'payloadHash': payloadHash,
      'payloadSignature': payloadSignature,
      'primaryPeerId': primaryPeerId,
      'primaryPublicKey': primaryPublicKey,
      'primaryAddress': primaryAddress,
      'payloadKey': payloadKey,
      'ephemeralPublicKey': ephemeralPublicKey,
      'needCompress': needCompress,
      'needEncrypt': needEncrypt,
      'needReceipt': needReceipt,
      'needReadReceipt': needReadReceipt,
    });
    return json;
  }
}

class MergedMessage extends BaseEntity {
  String? ownerPeerId;
  String? messageId;
  String? mergedMessageId;

  MergedMessage();

  MergedMessage.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        messageId = json['messageId'],
        mergedMessageId = json['mergedMessageId'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'messageId': messageId,
      'mergedMessageId': mergedMessageId,
    });
    return json;
  }
}

// 附件（单聊/群聊/频道/收藏）
class MessageAttachment extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? messageId; // 消息的唯一id标识
  String? targetPeerId; // 外键（对应targetPeerId）
  String?
      content; // 消息内容（基于mime+自定义标识区分内容类型，如：application/audio/image/message/text/video/x-word, contact联系人名片, groupChat群聊, channel频道）
  String? contentType;
  bool needCompress = true;
  bool needEncrypt = true;
  String? payloadHash;
  String? payloadSignature;
  String? payloadKey;

  MessageAttachment();

  MessageAttachment.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        messageId = json['messageId'],
        targetPeerId = json['targetPeerId'],
        content = json['content'],
        contentType = json['contentType'],
        needCompress = json['needCompress'] == true || json['needCompress'] == 1
            ? true
            : false,
        needEncrypt = json['needEncrypt'] == true || json['needEncrypt'] == 1
            ? true
            : false,
        payloadHash = json['payloadHash'],
        payloadSignature = json['payloadSignature'],
        payloadKey = json['payloadKey'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'messageId': messageId,
      'targetPeerId': targetPeerId,
      'content': content,
      'contentType': contentType,
      'needCompress': needCompress,
      'needEncrypt': needEncrypt,
      'payloadHash': payloadHash,
      'payloadSignature': payloadSignature,
      'payloadKey': payloadKey,
    });
    return json;
  }
}

// 发送接收记录（群聊联系人请求/群聊/频道）
class Receive extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? targetType; // 外键（对应message-targetType、对群聊联系人请求为LinkmanRequest）
  String? targetPeerId; // 外键（对应message-targetPeerId、对群聊联系人请求为空）
  String? messageType; // 外键（对应message-messageType、linkmanRequest-requestType）
  String? messageId; // 外键（对应message-messageId、linkmanRequest-_id）
  String? receiverPeerId; // 消息接收方peerId
  String? receiveTime; // 接收时间
  String? readTime; // 阅读时间
  Receive();

  Receive.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        targetType = json['targetType'],
        targetPeerId = json['targetPeerId'],
        messageType = json['messageType'],
        messageId = json['messageId'],
        receiverPeerId = json['receiverPeerId'],
        receiveTime = json['receiveTime'],
        readTime = json['readTime'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'targetType': targetType,
      'targetPeerId': targetPeerId,
      'messageType': messageType,
      'messageId': messageId,
      'receiverPeerId': receiverPeerId,
      'receiveTime': receiveTime,
      'readTime': readTime,
    });
    return json;
  }
}

/// party的最新消息汇总
/// 每次有新消息到达，则更新，每个party一条记录
class ChatSummary extends BaseEntity {
  String ownerPeerId; // 区分属主
  String? peerId; // 接收者或者发送者的联系人或群
  String? clientId; // 接收者或者发送者的联系人或群
  String? partyType; // 接收者或者发送者类型
  String? messageId; // 最新的消息Id
  String? messageType; // 最新的消息类型
  String? subMessageType; // 最新的消息子类型
  String? name; // 接收者或者发送者联系人或者群的名称
  String? avatar; //头像
  String? title; // 标题
  String? thumbBody; // 预览内容（适用需预览的content，如笔记、转发聊天）
  String? thumbnail; // 预览缩略图（base64图片，适用需预览的content，如笔记、联系人名片）
  String? content;
  String? contentType;
  String? sendReceiveTime; // 发送接收时间
  int unreadNumber = 0;
  String? payloadHash;
  String? payloadKey;

  ChatSummary(this.ownerPeerId);

  ChatSummary.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        peerId = json['peerId'],
        clientId = json['clientId'],
        partyType = json['partyType'],
        messageId = json['messageId'],
        messageType = json['messageType'],
        subMessageType = json['subMessageType'],
        avatar = json['avatar'],
        name = json['name'],
        title = json['title'],
        thumbBody = json['thumbBody'],
        thumbnail = json['thumbnail'],
        content = json['content'],
        contentType = json['contentType'],
        sendReceiveTime = json['sendReceiveTime'],
        unreadNumber = json['unreadNumber'],
        payloadKey = json['payloadKey'],
        payloadHash = json['payloadHash'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'peerId': peerId,
      'clientId': clientId,
      'partyType': partyType,
      'messageId': messageId,
      'messageType': messageType,
      'subMessageType': subMessageType,
      'avatar': avatar,
      'name': name,
      'title': title,
      'thumbBody': thumbBody,
      'thumbnail': thumbnail,
      'content': content,
      'contentType': contentType,
      'sendReceiveTime': sendReceiveTime,
      'unreadNumber': unreadNumber,
      'payloadKey': payloadKey,
      'payloadHash': payloadHash,
    });
    return json;
  }
}
