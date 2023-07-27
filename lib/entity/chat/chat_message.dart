import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/message_attachment.dart';
import 'package:colla_chat/provider/myself.dart';

enum ChatMessageContentType {
  rich, // 根据场景包含类型不同，如非系统类型、可搜索类型等
  image,
  text,
  html,
  json,
  file,
  audio,
  video,
  media,
  display,
  card,
  channel,
  url,
  location,
  action,
}

enum ChatMessageMimeType {
  text,
  html,
  json,
  md,
  gif,
  png,
  jpeg,
  jpg,
  bmp,
  webp,
  midi,
  mpeg,
  webm,
  ogg,
  wav,
  opus,
  xml,
  pdf,
  csv,
  xls,
  ppt,
  mp3,
  m4a,
  mp4,
  mov,
  rmvb,
  avi,
  wmv,
  mkv,
  mpg,
  aac,
}

// 消息类型（messageType）,system消息不在聊天界面显示
enum ChatMessageType {
  email,
  //聊天消息，在聊天界面上显示的消息
  chat,
  //系统消息，不在聊天界面上显示的消息
  system,
  //频道消息，就是自己发表的文章或者自己收藏的文章，不在聊天界面上显示的消息
  channel,
  //收藏消息，就是自己收藏的文章，经过发布可以成为channel类型，不在聊天界面上显示的消息
  collection,
}

enum ChatMessageSubType {
  addFriend, // 加好友请求
  modifyLinkman, //修改联系人信息，比如头像，名称
  addGroup, // 新建群聊
  dismissGroup, // 解散群聊
  modifyGroup, // 修改群信息
  addGroupMember, // 新增群聊成员
  removeGroupMember, // 删除群聊成员
  chat, // 联系人发送聊天消息
  predefine, // 系统预定义聊天消息，如群聊动态通知
  videoChat, // 视频聊天
  cancel, // 撤销聊天消息
  delete, // 删除聊天消息
  chatReceipt, // 聊天回复
  groupFile, // 群文件
  channel, //普通的频道消息
  comment, //评论
  getChannel, //请求获取最新的频道文
  collection,
  // 以下system消息，不在聊天界面显示
  signal, //webrtc signal消息，一般用于重新协商的情况
  preKeyBundle, //signal加解密
}

enum MessageStatus {
  draft,
  unsent, //未发送成功
  send, //发了，不知是否成功
  sent, //发送成功
  received, //已接收
  read, //已读
  deleted, //删除
  published, //发布
}

///消息回执的类型，写入receiptContent字段
enum MessageReceiptType {
  received, //是一种通用的消息回执，可用在所有的消息回执上，仅仅表示收到
  accepted, //同意，是一种视频消息的回执，表明同意消息的行为，视频的时候表示立即接听，相当于hold+join
  rejected, //拒绝，是一种视频消息的回执，表明拒绝消息的行为，视频的时候表示拒绝邀请
  terminated, //终止，是一种视频消息的回执，表明终止消息的行为，视频的时候表示曾经接收邀请，现在终止，后面不会加入
  busy, //忙，是一种视频消息的回执，表明自己忙，视频的时候表示因为忙拒绝邀请
  ignored, //忽视，是一种视频消息的回执，视频的时候表明有意或者无意地忽视，后面有可能加入
  hold, //保持，是一种视频消息的回执，视频的时候表明忙但是接受邀请，类似主动ignored，后面加入
  join, //加入，是一种视频消息的回执，表示现在进入视频会议状态，自己的本地视频传给所有人，请会议的所有人把器视频传给自己
  exit, //退出，是一种视频消息的回执，视频的时候表明加入后暂时退出，切断本地视频，后面可以再加入
}

///好友，群，潜在，联系人，频道，会议
enum PartyType { linkman, group, peerClient, contact, channel, conference }

enum ChatDirect { receive, send }

enum TransportType { none, chatGPT, websocket, webrtc, sfu, email, sms, nearby }

// 消息，泛指一切社交复合文档，最简单的是一句话，最复杂可以是非常复杂的混合文本，图片，视频的文档
class ChatMessage extends StatusEntity {
  String transportType =
      TransportType.webrtc.name; // 包括：websocket,webrtc,mail,sms
  String? messageId; // 消息的唯一id标识
  String messageType = ChatMessageType.chat.name; // 消息类型（对应channel消息类型）
  String subMessageType = ChatMessageSubType.chat.name;
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

  ///receiver五个字段填写接收者的信息
  ///消息发送时如果接收者是个人的时候可以填写，是群和会议的时候，信息不填写，在接收到信息后可以由接收方填写自己
  String? receiverPeerId; // 目标的唯一id标识（单聊对应linkman-peerId，群聊对应group-peerId）
  String? receiverClientId;
  String? receiverType; // 包括：Linkman(单聊),Group(群聊),Conference(会议),
  String? receiverName;
  String? receiverAddress;

  ///和群以及会议相关的字段
  String?
      groupId; // 目标的唯一id标识（单聊对应linkman-peerId，群聊对应group-peerId，会议对应conferenceId）
  String? groupName;
  String? groupType; // 包括：Group(群聊),Conference(会议),
  String? receiveTime; // 接收时间
  String? receiptTime; // 发送回执时间
  String? readTime; // 阅读时间
  String? title; // 消息标题
  String? thumbnail; // 预览缩略图（base64图片，适用需预览的content，如笔记、联系人名片）
  String? content; // 消息内容
  String? receiptType; // 回执的内容
  String? contentType;
  String? mimeType;
  int deleteTime = 0; // 阅读后的删除时间，秒数，0表示不删除
  String? parentMessageId; //引用的消息编号
  bool needCompress = false;
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

  ChatMessage();

  ChatMessage.fromJson(Map json)
      : transportType = json['transportType'] ?? TransportType.webrtc.name,
        direct = json['direct'],
        receiverPeerId = json['receiverPeerId'],
        receiverType = json['receiverType'],
        receiverClientId = json['receiverClientId'],
        receiverName = json['receiverName'],
        receiverAddress = json['receiverAddress'],
        groupId = json['groupId'],
        groupName = json['groupName'],
        groupType = json['groupType'],
        messageId = json['messageId'],
        messageType = json['messageType'] ?? ChatMessageType.chat.name,
        subMessageType = json['subMessageType'] ?? ChatMessageSubType.chat.name,
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
        receiptType = json['receiptType'],
        thumbnail = json['thumbnail'],
        content = json['content'],
        contentType = json['contentType'],
        mimeType = json['mimeType'],
        deleteTime = json['deleteTime'],
        parentMessageId = json['parentMessageId'],
        payloadHash = json['payloadHash'],
        payloadSignature = json['payloadSignature'],
        primaryPeerId = json['primaryPeerId'],
        primaryPublicKey = json['primaryPublicKey'],
        primaryAddress = json['primaryAddress'],
        payloadKey = json['payloadKey'],
        ephemeralPublicKey = json['ephemeralPublicKey'],
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
      'transportType': transportType,
      'direct': direct,
      'receiverPeerId': receiverPeerId,
      'receiverType': receiverType,
      'receiverClientId': receiverClientId,
      'receiverName': receiverName,
      'receiverAddress': receiverAddress,
      'groupId': groupId,
      'groupName': groupName,
      'groupType': groupType,
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
      'receiptType': receiptType,
      'thumbnail': thumbnail,
      'content': content,
      'contentType': contentType,
      'mimeType': mimeType,
      'deleteTime': deleteTime,
      'parentMessageId': parentMessageId,
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

  ///是否是自己发送的消息
  bool get isMyself {
    bool isMyself = false;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      isMyself = true;
    }
    return isMyself;
  }

  ///是否是预定义消息，显示在中间，在群的时候表示群消息
  bool get isPredefine {
    bool isPredefine = false;
    if (subMessageType == ChatMessageSubType.predefine.name) {
      isPredefine = true;
    }
    return isPredefine;
  }
}

class MergedMessage extends BaseEntity {
  String? messageId;
  String? mergedMessageId;

  MergedMessage();

  MergedMessage.fromJson(Map json)
      : messageId = json['messageId'],
        mergedMessageId = json['mergedMessageId'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'messageId': messageId,
      'mergedMessageId': mergedMessageId,
    });
    return json;
  }
}

// 发送接收记录（群聊联系人请求/群聊/频道）
class Receive extends BaseEntity {
  String? targetType; // 外键（对应message-targetType、对群聊联系人请求为LinkmanRequest）
  String? targetPeerId; // 外键（对应message-targetPeerId、对群聊联系人请求为空）
  String? messageType; // 外键（对应message-messageType、linkmanRequest-requestType）
  String? messageId; // 外键（对应message-messageId、linkmanRequest-_id）
  String? receiverPeerId; // 消息接收方peerId
  String? receiveTime; // 接收时间
  String? readTime; // 阅读时间
  Receive();

  Receive.fromJson(Map json)
      : targetType = json['targetType'],
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
