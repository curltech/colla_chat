import 'dart:typed_data';
import 'package:libsignal/libsignal.dart';

/// Signal协议的密钥对
class SignalKeyPair {
  late int registrationId;
  late IdentityKeyPair identityKeyPair;
  late List<PreKeyRecord> preKeys;
  late SignedPreKeyRecord signedPreKey;

  ///本地的存储
  late InMemoryPreKeyStore preKeyStore;
  late InMemorySessionStore sessionStore;
  late InMemorySignedPreKeyStore signedPreKeyStore;
  late InMemoryIdentityKeyStore identityKeyStore;

  ///群发的功能
  late InMemorySenderKeyStore senderKeyStore = InMemorySenderKeyStore();

  SignalKeyPair();

  /// 在初始化的时候，客户端需要产生注册编号，身份密钥对，预先生成的密钥对数组，签名后的预先密钥对
  /// 并序列化存储起来，方便后续使用
  Future<void> init() async {
    await LibSignal.init();
    //身份密钥对
    identityKeyPair = IdentityKeyPair.generate();
    //预先生成的密钥对数组，用于每次的会话加密
    //产生签名后的预先密钥对

    //对生成的身份密钥对，预先密钥对，签名预先密钥对定义序列化存储
    //并序列化存储起来
    sessionStore = InMemorySessionStore();
    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    //序列化存储身份密钥对
    identityKeyStore =
        InMemoryIdentityKeyStore(identityKeyPair, registrationId);

    senderKeyStore = InMemorySenderKeyStore();
  }
}

/// 特定目标的signal加密会话，
/// 当与另外的客户端通信的时候，在连接通道成功建立以后，就可以建立signal加密会话，然后进行消息的加解密
class SignalSession {
  //对方客户端的peerId
  String peerId;

  //对方客户端的clientId
  String clientId;
  int deviceId;

  ///群发的会话
  SenderKeyName? groupSender;
  GroupCipher? groupSession;

  // 对方客户端的第一个预先的密钥对包，可以通过服务器获取到
  late PreKeyBundle retrievedPreKeyBundle;

  late SessionCipher sessionCipher;

  SignalSession(
      {required this.peerId,
      required this.clientId,
      this.deviceId = 1,
      String? groupId,
      required this.retrievedPreKeyBundle}) {}

  Future<void> init() async {}

  ///没搞懂怎么用
  Future<void> groupProcess(Uint8List data) async {}
}
