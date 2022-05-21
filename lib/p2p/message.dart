import 'dart:typed_data';
import 'package:colla_chat/tool/util.dart';
import '../crypto/util.dart';

class ChainMessage {
  late String UUID;

  /// 最终的消息接收目标，如果当前节点不是最终的目标，可以进行转发
  /// 如果目标是服务器节点，直接转发，
  /// 如果目标是客户机节点，先找到客户机目前连接的服务器节点，也许就是自己，然后转发
  String? TargetPeerId;
  String? TargetConnectPeerId;
  String? TargetConnectSessionId;

  ///
  ///   以下两个字段方便对消息处理时寻找目的节点
  ///
  String? Topic;

  /// src字段在发送的时候不填，到接收端自动填充,ConnectSessionId在发送的时候不填，到接收端自动填充
  /// ,第一个连接节点
  String? SrcConnectSessionId;
  String? SrcConnectPeerId;
  String? LocalConnectPeerId;
  String? LocalConnectAddress;
  String? SrcPeerId;
  String? SrcAddress;
  String? ConnectPeerId;
  String? ConnectAddress;
  String? ConnectSessionId;
  late String MessageType;
  String? Tip;
  String? MessageDirect;

  /// 经过目标peer的公钥加密过的对称密钥，这个对称密钥是随机生成，每次不同，用于加密payload
  String? PayloadKey;
  bool NeedCompress = true;
  bool NeedEncrypt = true;
  bool NeedSlice = false;
  SecurityContext? securityContext;

  /// 消息负载序列化后的寄送格式，再经过客户端自己的加密方式比如openpgp（更安全）加密，签名，压缩，base64处理后的字符串
  String? TransportPayload;

  /// 不跨网络传输，是transportPayload检验过后还原的对象，传输时通过转换成transportPayload传输
  dynamic Payload;

  /// 负载json的源peer的签名
  String? PayloadSignature;
  String? PreviousPublicKeyPayloadSignature;

  ///
  /// 根据此字段来把TransportPayload对应的字节还原成Payload的对象，最简单的就是字符串
  /// 也可以是一个复杂的结构，但是dht的数据结构（peerendpoint），通用网络块存储（datablock）一般不用这种方式操作
  /// 二采用getvalue和putvalue的方式操作
  ///
  String? PayloadType;
  String? CreateTimestamp;

  int SliceSize = 0;
  int SliceNumber = 0;

  ChainMessage();

  ChainMessage.fromJson(Map json)
      : UUID = json['UUID'],
        TargetPeerId = json['TargetPeerId'],
        TargetConnectPeerId = json['TargetConnectPeerId'],
        TargetConnectSessionId = json['TargetConnectSessionId'],
        Topic = json['Topic'],
        SrcConnectSessionId = json['SrcConnectSessionId'],
        SrcConnectPeerId = json['SrcConnectPeerId'],
        LocalConnectPeerId = json['LocalConnectPeerId'],
        LocalConnectAddress = json['LocalConnectAddress'],
        SrcPeerId = json['SrcPeerId'],
        SrcAddress = json['SrcAddress'],
        ConnectPeerId = json['ConnectPeerId'],
        ConnectAddress = json['ConnectAddress'],
        ConnectSessionId = json['ConnectSessionId'],
        MessageType = json['MessageType'],
        Tip = json['Tip'],
        MessageDirect = json['MessageDirect'],
        PayloadKey = json['PayloadKey'],
        NeedCompress = json['NeedCompress'],
        NeedEncrypt = json['NeedEncrypt'],
        NeedSlice = json['NeedSlice'],
        securityContext = json['securityContext'],
        TransportPayload = json['TransportPayload'],
        Payload = json['Payload'],
        PayloadSignature = json['PayloadSignature'],
        PreviousPublicKeyPayloadSignature =
            json['PreviousPublicKeyPayloadSignature'],
        PayloadType = json['PayloadType'],
        CreateTimestamp = json['CreateTimestamp'],
        SliceSize = json['SliceSize'],
        SliceNumber = json['SliceNumber'];

  Map<String, dynamic> toJson() => {
        'UUID': UUID,
        'TargetPeerId': TargetPeerId,
        'TargetConnectPeerId': TargetConnectPeerId,
        'TargetConnectSessionId': TargetConnectSessionId,
        'Topic': Topic,
        'SrcConnectSessionId': SrcConnectSessionId,
        'SrcConnectPeerId': SrcConnectPeerId,
        'LocalConnectPeerId': LocalConnectPeerId,
        'LocalConnectAddress': LocalConnectAddress,
        'SrcPeerId': SrcPeerId,
        'SrcAddress': SrcAddress,
        'ConnectPeerId': ConnectPeerId,
        'ConnectAddress': ConnectAddress,
        'ConnectSessionId': ConnectSessionId,
        'MessageType': MessageType,
        'Tip': Tip,
        'MessageDirect': MessageDirect,
        'PayloadKey': PayloadKey,
        'NeedCompress': NeedCompress,
        'NeedEncrypt': NeedEncrypt,
        'NeedSlice': NeedSlice,
        'securityContext': securityContext,
        'TransportPayload': TransportPayload,
        'Payload': Payload,
        'PayloadSignature': PayloadSignature,
        'PreviousPublicKeyPayloadSignature': PreviousPublicKeyPayloadSignature,
        'PayloadType': PayloadType,
        'CreateTimestamp': CreateTimestamp,
        'SliceSize': SliceSize,
        'SliceNumber': SliceNumber,
      };
}

class SecurityContext {
  String? Protocol;
  String? KeyFactoryAlgorithm;
  String? KeyStoreType;
  String? KeyPairAlgorithm;
  String? KeyPairType;
  int? KeyPairLength;
  String? SecretKeyAlgorithm;
  int? SecretKeySize;
  int? HashKeySize;
  String? AsymmetricalAlgorithm;
  String? SymmetricalAlgorithm;
  String? SignatureAlgorithm;
  String? MessageDigestAlgorithm;
  String? KeyGeneratorAlgorithm;
  String? HmacAlgorithm;
  String? Username;
  String? Password;

  SecurityContext.fromJson(Map json)
      : KeyFactoryAlgorithm = json['KeyFactoryAlgorithm'],
        KeyStoreType = json['KeyStoreType'],
        KeyPairAlgorithm = json['KeyPairAlgorithm'],
        KeyPairType = json['KeyPairType'],
        KeyPairLength = json['KeyPairLength'],
        SecretKeyAlgorithm = json['SecretKeyAlgorithm'],
        SecretKeySize = json['SecretKeySize'],
        HashKeySize = json['HashKeySize'],
        AsymmetricalAlgorithm = json['AsymmetricalAlgorithm'],
        SymmetricalAlgorithm = json['SymmetricalAlgorithm'],
        SignatureAlgorithm = json['SignatureAlgorithm'],
        MessageDigestAlgorithm = json['MessageDigestAlgorithm'],
        KeyGeneratorAlgorithm = json['KeyGeneratorAlgorithm'],
        HmacAlgorithm = json['HmacAlgorithm'],
        Username = json['Username'],
        Password = json['Password'];

  Map<String, dynamic> toJson() => {
        'Protocol': Protocol,
        'KeyFactoryAlgorithm': KeyFactoryAlgorithm,
        'KeyStoreType': KeyStoreType,
        'KeyPairAlgorithm': KeyPairAlgorithm,
        'KeyPairType': KeyPairType,
        'KeyPairLength': KeyPairLength,
        'SecretKeyAlgorithm': SecretKeyAlgorithm,
        'SecretKeySize': SecretKeySize,
        'HashKeySize': HashKeySize,
        'AsymmetricalAlgorithm': AsymmetricalAlgorithm,
        'SymmetricalAlgorithm': SymmetricalAlgorithm,
        'SignatureAlgorithm': SignatureAlgorithm,
        'MessageDigestAlgorithm': MessageDigestAlgorithm,
        'KeyGeneratorAlgorithm': KeyGeneratorAlgorithm,
        'HmacAlgorithm': HmacAlgorithm,
        'Username': Username,
        'Password': Password,
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

class MessageSerializer {
  MessageSerializer();

  static Uint8List marshal(dynamic value) {
    String json = '${JsonUtil.toJsonString(value)}\n';

    return CryptoUtil.strToUint8List(json);
  }

  static Map unmarshal(List<int> data) {
    var json = CryptoUtil.uint8ListToStr(data);

    return JsonUtil.toMap(json);
  }
}
