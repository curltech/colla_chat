import '../base.dart';

/**
 * 聊天的定义
 */

var period = 300; //5m

enum ChatDataType { MESSAGE, RECEIVE, ATTACH, CHAT, MERGEMESSAGE }

enum ChatContentType {
  All, // 根据场景包含类型不同，如非系统类型、可搜索类型等
  Image,
  Text,
  File,
  Audio,
  Video,
  Card,
  Note,
  Channel,
  Article,
  Chat,
  Link,
  Voice,
  Position,
  AUDIO_INVITATION,
  AUDIO_HISTORY,
  VIDEO_HISTORY,
  VIDEO_INVITATION,
  CALL_JOIN_REQUEST,
  EVENT,
  TIME,
  MEDIA_REJECT,
  MEDIA_CLOSE,
  MEDIA_BUSY
}

// 消息类型（messageType）
enum P2pChatMessageType {
  ADD_LINKMAN, // 新增联系人请求
  ADD_LINKMAN_REPLY, // 新增联系人请求的回复
  SYNC_LINKMAN_INFO, // 联系人基本信息同步
  DROP_LINKMAN, // 从好友中删除
  DROP_LINKMAN_RECEIPT, // 删除好友通知回复
  BLACK_LINKMAN, // 加入黑名单
  BLACK_LINKMAN_RECEIPT, // 加入黑名单通知回复
  UNBLACK_LINKMAN, // 从黑名单中移除
  UNBLACK_LINKMAN_RECEIPT, // 移除黑名单通知回复
  // 联系人请求
  ADD_GROUPCHAT, // 新增群聊请求
  ADD_GROUPCHAT_RECEIPT, // 新增群聊请求接收回复
  DISBAND_GROUPCHAT, // 解散群聊请求
  DISBAND_GROUPCHAT_RECEIPT, // 解散群聊请求接收回复
  MODIFY_GROUPCHAT, // 修改群聊请求
  MODIFY_GROUPCHAT_RECEIPT, // 修改群聊请求接收回复
  MODIFY_GROUPCHAT_OWNER, // 修改群主请求
  MODIFY_GROUPCHAT_OWNER_RECEIPT, // 修改群主请求接收回复
  ADD_GROUPCHAT_MEMBER, // 新增群聊成员请求
  ADD_GROUPCHAT_MEMBER_RECEIPT, // 新增群聊成员请求接收回复
  REMOVE_GROUPCHAT_MEMBER, // 删除群聊成员请求
  REMOVE_GROUPCHAT_MEMBER_RECEIPT, // 删除群聊成员请求接收回复
  // 聊天
  CHAT_SYS, // 系统预定义聊天消息，如群聊动态通知
  CHAT_LINKMAN, // 联系人发送聊天消息
  CHAT_RECEIVE_RECEIPT, // 接收回复
  CALL_CLOSE,
  CALL_REQUEST, // 通话请求
  RECALL,
  GROUP_FILE
}

enum ChatMessageStatus {
  NORMAL,
  RECALL,
  DELETE,
}

enum SubjectType {
  CHAT,
  LINKMAN_REQUEST,
  GROUP_CHAT,
}

// 消息（单聊/群聊），以后想设计成泛指一切社交复合文档，最简单的是一句话，最复杂可以是非常复杂的混合文本，图片，视频的文档
class ChatMessage extends StatusEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? subjectType; // 包括：Chat（单聊）, GroupChat（群聊）
  String? subjectId; // 主题的唯一id标识（单聊对应linkman-peerId，群聊对应group-groupId）
  String? messageId; // 消息的唯一id标识
  String? messageType; // 消息类型（对应channel消息类型）
  String? senderPeerId; // 消息发送方（作者）peerId
  String? receiveTime; // 接收时间
  String?
      actualReceiveTime; // 实际接收时间 1.发送端发送消息时receiveTime=createDate，actualReceiveTime=null；2.根据actualReceiveTime是否为null判断是否需要重发，收到接受回执时更新actualReceiveTime；3.聊天区按receiveTime排序，查找聊天内容按createDate排序
  String? readTime; // 阅读时间
  String? title; // 消息标题
  String? thumbBody; // 预览内容（适用需预览的content，如笔记、转发聊天）
  String? thumbnail; // 预览缩略图（base64图片，适用需预览的content，如笔记、联系人名片）
  String? contentType;
  String? destroyTime;
  String? primaryPeerId;

  /// primary peer的publicKey
  String? primaryPublicKey;
  String? primaryAddress;
  String? ephemeralPublicKey;

  String? content; // 消息内容
  bool needCompress = true;
  bool needEncrypt = true;
  String? payloadHash;
  String? payloadSignature;
  String? payloadKey;

// 其它: 加密相关字段，自动销毁相关字段

  ChatMessage();

  ChatMessage.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        subjectType = json['subjectType'],
        subjectId = json['subjectId'],
        messageId = json['messageId'],
        messageType = json['messageType'],
        senderPeerId = json['senderPeerId'],
        receiveTime = json['receiveTime'],
        actualReceiveTime = json['actualReceiveTime'],
        readTime = json['readTime'],
        title = json['title'],
        thumbBody = json['thumbBody'],
        thumbnail = json['thumbnail'],
        content = json['content'],
        contentType = json['contentType'],
        destroyTime = json['destroyTime'],
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
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'subjectType': subjectType,
      'subjectId': subjectId,
      'messageId': messageId,
      'messageType': messageType,
      'senderPeerId': senderPeerId,
      'receiveTime': receiveTime,
      'actualReceiveTime': actualReceiveTime,
      'readTime': readTime,
      'title': title,
      'thumbBody': thumbBody,
      'thumbnail': thumbnail,
      'content': content,
      'contentType': contentType,
      'destroyTime': destroyTime,
      'payloadHash': payloadHash,
      'payloadSignature': payloadSignature,
      'primaryPeerId': primaryPeerId,
      'primaryPublicKey': primaryPublicKey,
      'primaryAddress': primaryAddress,
      'payloadKey': payloadKey,
      'ephemeralPublicKey': ephemeralPublicKey,
      'needCompress': needCompress,
      'needEncrypt': needEncrypt,
    });
    return json;
  }
}

class MergeMessage extends BaseEntity {
  String? ownerPeerId;
  String? mergeMessageId;
  String? createDate;

  MergeMessage();

  MergeMessage.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        mergeMessageId = json['mergeMessageId'],
        createDate = json['createDate'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'mergeMessageId': mergeMessageId,
      'createDate': createDate,
    });
    return json;
  }
}

// 附件（单聊/群聊/频道/收藏）
class ChatAttach extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? messageId; // 消息的唯一id标识
  String? subjectId; // 外键（对应subject-subjectId）
  String?
      content; // 消息内容（基于mime+自定义标识区分内容类型，如：application/audio/image/message/text/video/x-word, contact联系人名片, groupChat群聊, channel频道）

  bool needCompress = true;
  bool needEncrypt = true;
  String? payloadHash;
  String? payloadSignature;
  String? payloadKey;

  ChatAttach();

  ChatAttach.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        messageId = json['messageId'],
        subjectId = json['subjectId'],
        content = json['content'],
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
      'subjectId': subjectId,
      'content': content,
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
  String? subjectType; // 外键（对应message-subjectType、对群聊联系人请求为LinkmanRequest）
  String? subjectId; // 外键（对应message-subjectId、对群聊联系人请求为空）
  String? messageType; // 外键（对应message-messageType、linkmanRequest-requestType）
  String? messageId; // 外键（对应message-messageId、linkmanRequest-_id）
  String? receiverPeerId; // 消息接收方peerId
  String? receiveTime; // 接收时间
  Receive();

  Receive.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        subjectType = json['subjectType'],
        subjectId = json['subjectId'],
        messageType = json['messageType'],
        messageId = json['messageId'],
        receiverPeerId = json['receiverPeerId'],
        receiveTime = json['receiveTime'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'subjectType': subjectType,
      'subjectId': subjectId,
      'messageType': messageType,
      'messageId': messageId,
      'receiverPeerId': receiverPeerId,
      'receiveTime': receiveTime,
    });
    return json;
  }
}

class Chat extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? subjectType; // 包括：Chat（单聊）, GroupChat（群聊）
  String? subjectId; // 主题的唯一id标识（单聊对应linkman-peerId，群聊对应group-groupId）
  String? content;

  Chat();

  Chat.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        subjectType = json['subjectType'],
        subjectId = json['subjectId'],
        content = json['content'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'subjectType': subjectType,
      'subjectId': subjectId,
      'content': content,
    });
    return json;
  }
}
