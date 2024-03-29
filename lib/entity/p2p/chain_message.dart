import 'package:colla_chat/entity/p2p/security_context.dart';

class ChainMessage extends SecurityContext {
  String? uuid;
  String? topic;

  /// 最终的消息接收目标，如果当前节点不是最终的目标，可以进行转发
  /// 如果目标是服务器节点，直接转发，
  /// 如果目标是客户机节点，先找到客户机目前连接的服务器节点，也许就是自己，然后转发
  String? targetConnectPeerId;

  // String? targetConnectSessionId;
  String? targetConnectAddress;

  /// src字段在发送的时候不填，到接收端自动填充,ConnectSessionId在发送的时候不填，到接收端自动填充
  /// ,第一个连接节点
  String? srcClientId;
  String? srcConnectSessionId;
  String? srcConnectPeerId;
  String? srcConnectAddress;

  ///本次连接的信息,一般与target的值一致
  ///因为chain message趋向与发送给目标的连接peerendpoint
  String? connectPeerId;
  String? connectAddress;
  String? connectSessionId;
  late String messageType;
  String? tip;
  String? messageDirect;
  bool needSlice = false;

  /// 二进制格式的消息负载经过base64后的寄送格式，字符串
  String? transportPayload;

  ///
  /// 根据此字段来把TransportPayload对应的字节还原成Payload的对象，最简单的就是字符串
  /// 也可以是一个复杂的结构，但是dht的数据结构（peerendpoint），通用网络块存储（datablock）一般不用这种方式操作
  /// 二采用getvalue和putvalue的方式操作
  ///
  String? payloadType;
  String? createTimestamp;

  int sliceSize = 0;
  int sliceNumber = 0;
  int statusCode = 0;

  ChainMessage();

  ChainMessage.fromJson(super.json)
      : uuid = json['uuid'] ?? '',
        topic = json['topic'],
        targetConnectPeerId = json['targetConnectPeerId'],
        // targetConnectSessionId = json['targetConnectSessionId'],
        targetConnectAddress = json['targetConnectAddress'],
        srcConnectSessionId = json['srcConnectSessionId'],
        srcConnectPeerId = json['srcConnectPeerId'],
        srcConnectAddress = json['srcConnectAddress'],
        srcClientId = json['srcClientId'],
        connectPeerId = json['connectPeerId'],
        connectAddress = json['connectAddress'],
        connectSessionId = json['connectSessionId'],
        messageType = json['messageType'],
        tip = json['tip'],
        messageDirect = json['messageDirect'],
        needSlice =
            json['needSlice'] == true || json['needSlice'] == 1 ? true : false,
        payloadType = json['payloadType'],
        createTimestamp = json['createTimestamp'],
        sliceSize = json['sliceSize'] ?? 0,
        sliceNumber = json['sliceNumber'] ?? 0,
        statusCode = json['statusCode'] ?? 0,
        transportPayload = json['transportPayload'] ?? '',
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'uuid': uuid,
      'topic': topic,
      'targetConnectPeerId': targetConnectPeerId,
      // 'targetConnectSessionId': targetConnectSessionId,
      'targetConnectAddress': targetConnectAddress,
      'srcConnectPeerId': srcConnectPeerId,
      'srcConnectSessionId': srcConnectSessionId,
      'srcClientId': srcClientId,
      'srcConnectAddress': srcConnectAddress,
      'connectPeerId': connectPeerId,
      'connectAddress': connectAddress,
      'connectSessionId': connectSessionId,
      'messageType': messageType,
      'tip': tip,
      'messageDirect': messageDirect,
      'needSlice': needSlice,
      'payloadType': payloadType,
      'createTimestamp': createTimestamp,
      'sliceSize': sliceSize,
      'sliceNumber': sliceNumber,
      'statusCode': statusCode,
      'transportPayload': transportPayload,
    });
    return json;
  }
}

class SecurityProtocol {
  String? protocol;
  String? keyFactoryAlgorithm;
  String? keyStoreType;
  String? keyPairAlgorithm;
  String? keyPairType;
  int? keyPairLength;
  String? secretKeyAlgorithm;
  int? secretKeySize;
  int? hashKeySize;
  String? asymmetricalAlgorithm;
  String? symmetricalAlgorithm;
  String? signatureAlgorithm;
  String? messageDigestAlgorithm;
  String? keyGeneratorAlgorithm;
  String? hmacAlgorithm;
  String? username;
  String? password;

  SecurityProtocol.fromJson(Map json)
      : keyFactoryAlgorithm = json['keyFactoryAlgorithm'],
        keyStoreType = json['keyStoreType'],
        keyPairAlgorithm = json['keyPairAlgorithm'],
        keyPairType = json['keyPairType'],
        keyPairLength = json['keyPairLength'],
        secretKeyAlgorithm = json['secretKeyAlgorithm'],
        secretKeySize = json['secretKeySize'],
        hashKeySize = json['hashKeySize'],
        asymmetricalAlgorithm = json['asymmetricalAlgorithm'],
        symmetricalAlgorithm = json['symmetricalAlgorithm'],
        signatureAlgorithm = json['signatureAlgorithm'],
        messageDigestAlgorithm = json['messageDigestAlgorithm'],
        keyGeneratorAlgorithm = json['keyGeneratorAlgorithm'],
        hmacAlgorithm = json['hmacAlgorithm'],
        username = json['username'],
        password = json['password'];

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'keyFactoryAlgorithm': keyFactoryAlgorithm,
        'keyStoreType': keyStoreType,
        'keyPairAlgorithm': keyPairAlgorithm,
        'keyPairType': keyPairType,
        'keyPairLength': keyPairLength,
        'secretKeyAlgorithm': secretKeyAlgorithm,
        'secretKeySize': secretKeySize,
        'hashKeySize': hashKeySize,
        'asymmetricalAlgorithm': asymmetricalAlgorithm,
        'symmetricalAlgorithm': symmetricalAlgorithm,
        'signatureAlgorithm': signatureAlgorithm,
        'messageDigestAlgorithm': messageDigestAlgorithm,
        'keyGeneratorAlgorithm': keyGeneratorAlgorithm,
        'hmacAlgorithm': hmacAlgorithm,
        'username': username,
        'password': password,
      };
}

enum MsgType {
  // 未定义
  UNDEFINED,
  // 消息返回正确
  OK,
  // 消息返回正确，但等待所有数据到齐
  WAIT,
  // 消息返回错误
  ERROR,
  // 发送消息peer对接收者来说不可信任
  UNTRUST,
  // 消息超时无响应
  NO_RESPONSE,
  // 通用消息返回，表示可能异步返回
  RESPONSE,
  // 消息被拒绝
  REJECT,
  MANAGEROOM,
  // 可做心跳测试
  PING,
  // 发送聊天报文
  P2PCHAT,
  CHAT,
  FINDPEER,
  GETVALUE,
  PUTVALUE,
  SIGNAL,
  IONSIGNAL,
  RTCCANDIDATE,
  RTCANSWER,
  RTCOFFER,
  // PeerClient连接
  CONNECT,
  // PeerClient查找
  FINDCLIENT,
  // DataBlock查找
  QUERYVALUE,
  // PeerTrans查找
  QUERYPEERTRANS,
  // DataBlock保存共识消息
  CONSENSUS,
  CONSENSUS_REPLY,
  CONSENSUS_PREPREPARED,
  CONSENSUS_PREPARED,
  CONSENSUS_COMMITED,
  CONSENSUS_RAFT,
  CONSENSUS_RAFT_REPLY,
  CONSENSUS_RAFT_PREPREPARED,
  CONSENSUS_RAFT_PREPARED,
  CONSENSUS_RAFT_COMMITED,
  CONSENSUS_PBFT,
  CONSENSUS_PBFT_REPLY,
  CONSENSUS_PBFT_PREPREPARED,
  CONSENSUS_PBFT_PREPARED,
  CONSENSUS_PBFT_COMMITED
}

enum MsgDirect { Request, Response }
