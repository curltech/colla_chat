import 'dart:convert';
import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

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
  late InMemorySignalProtocolStore signalProtocolStore;

  ///群发的功能
  late InMemorySenderKeyStore senderKeyStore = InMemorySenderKeyStore();

  SignalKeyPair() {
    init();
  }

  /// 在初始化的时候，客户端需要产生注册编号，身份密钥对，预先生成的密钥对数组，签名后的预先密钥对
  /// 并序列化存储起来，方便后续使用
  init() async {
    //注册编号
    registrationId = generateRegistrationId(false);
    //身份密钥对
    identityKeyPair = generateIdentityKeyPair();
    //预先生成的密钥对数组，用于每次的会话加密
    preKeys = generatePreKeys(0, 110);
    //产生签名后的预先密钥对
    signedPreKey = generateSignedPreKey(identityKeyPair, 0);

    //对生成的身份密钥对，预先密钥对，签名预先密钥对定义序列化存储
    //并序列化存储起来
    sessionStore = InMemorySessionStore();
    preKeyStore = InMemoryPreKeyStore();
    signedPreKeyStore = InMemorySignedPreKeyStore();
    //序列化存储身份密钥对
    identityKeyStore =
        InMemoryIdentityKeyStore(identityKeyPair, registrationId);
    //序列化存储预先密钥对
    for (var p in preKeys) {
      await preKeyStore.storePreKey(p.id, p);
    }
    //序列化存储签名预先密钥对
    await signedPreKeyStore.storeSignedPreKey(signedPreKey.id, signedPreKey);

    //协议存储，用于解密操作
    signalProtocolStore =
        InMemorySignalProtocolStore(identityKeyPair, registrationId);
    for (final p in preKeys) {
      await signalProtocolStore.storePreKey(p.id, p);
    }
    await signalProtocolStore.storeSignedPreKey(signedPreKey.id, signedPreKey);

    senderKeyStore = InMemorySenderKeyStore();
  }

  // 产生预先密钥对包，一般是第一个预先密钥对，签名预先密钥对，身份密钥对等参数组成，
  // 通过服务器传递给对方，才能启动会话
  PreKeyBundle getPreKeyBundle({int index = 0, int deviceId = 1}) {
    final preKeyBundle = PreKeyBundle(
        registrationId,
        deviceId,
        preKeys[index].id,
        preKeys[index].getKeyPair().publicKey,
        signedPreKey.id,
        signedPreKey.getKeyPair().publicKey,
        signedPreKey.signature,
        identityKeyPair.getPublicKey());

    return preKeyBundle;
  }

  exportPreKeyBundle() {}

  importPreKeyBundle() {}
}

/// 特定目标的signal加密会话，
/// 当与另外的客户端通信的时候，在连接通道成功建立以后，就可以建立signal加密会话，然后进行消息的加解密
class SignalSession {
  //对方客户端的peerId
  String peerId;

  //对方客户端的clientId
  String clientId;
  int deviceId;
  late SignalProtocolAddress signalProtocolAddress;

  ///群发的会话
  SenderKeyName? groupSender;
  GroupSessionBuilder? groupSessionBuilder;
  GroupCipher? groupSession;

  // 对方客户端的第一个预先的密钥对包，可以通过服务器获取到
  late PreKeyBundle retrievedPreKeyBundle;

  late SessionCipher sessionCipher;

  SignalSession(
      {required this.peerId,
      required this.clientId,
      this.deviceId = 1,
      String? groupId,
      required this.retrievedPreKeyBundle}) {
    //生成对方客户端的地址
    signalProtocolAddress =
        SignalProtocolAddress('$peerId:$clientId', deviceId);
    ///以下未群组的功能
    if (groupId != null) {
      groupSender =
          SenderKeyName(groupId, signalSessionPool.signalProtocolAddress);
      groupSession = GroupCipher(
          signalSessionPool.signalKeyPair.senderKeyStore, groupSender!);
      groupSessionBuilder =
          GroupSessionBuilder(signalSessionPool.signalKeyPair.senderKeyStore);
    }
  }

  init() async {
    //产生会话builder
    var sessionBuilder = SessionBuilder(
        signalSessionPool.signalKeyPair.sessionStore,
        signalSessionPool.signalKeyPair.preKeyStore,
        signalSessionPool.signalKeyPair.signedPreKeyStore,
        signalSessionPool.signalKeyPair.identityKeyStore,
        signalProtocolAddress);
    //处理预先密钥对包
    await sessionBuilder.processPreKeyBundle(retrievedPreKeyBundle);
    //产生会话加密器
    sessionCipher = SessionCipher(
        signalSessionPool.signalKeyPair.sessionStore,
        signalSessionPool.signalKeyPair.preKeyStore,
        signalSessionPool.signalKeyPair.signedPreKeyStore,
        signalSessionPool.signalKeyPair.identityKeyStore,
        signalProtocolAddress);
  }

  ///没搞懂怎么用
  Future<Uint8List> groupCreate() async {
    final sentDistributionMessage =
        await groupSessionBuilder!.create(groupSender!);
    return sentDistributionMessage.serialize();
  }

  ///没搞懂怎么用
  groupProcess(Uint8List data) async {
    final receivedDistributionMessage =
        SenderKeyDistributionMessageWrapper.fromSerialized(data);
    await groupSessionBuilder!
        .process(groupSender!, receivedDistributionMessage);
  }

  ///在会话加密器产生后，加密
  Future<Uint8List> groupEncrypt(Uint8List data) async {
    if (groupSession != null) {
      var ciphertext = await groupSession!.encrypt(data);

      return ciphertext;
    }
    return data;
  }

  ///在会话加密器产生后，加密
  Future<Uint8List> groupDecrypt(Uint8List data) async {
    if (groupSession != null) {
      var ciphertext = await groupSession!.decrypt(data);

      return ciphertext;
    }
    return data;
  }

  ///在会话加密器产生后，加密
  Future<CiphertextMessage> encrypt(Uint8List data) async {
    var ciphertext = await sessionCipher.encrypt(data);

    return ciphertext;
  }

  ///在会话加密器产生后，解密
  Future<Uint8List> decrypt(CiphertextMessage ciphertext) async {
    var signalProtocolStore =
        signalSessionPool.signalKeyPair.signalProtocolStore;
    var sessionCipher =
        SessionCipher.fromStore(signalProtocolStore, signalProtocolAddress);

    // ciphertext: MessageType
    var messageType = ciphertext.getType();
    Uint8List? plaintext;
    if (messageType == CiphertextMessage.prekeyType) {
      plaintext =
          await sessionCipher.decrypt(ciphertext as PreKeySignalMessage);
    } else if (messageType == CiphertextMessage.whisperType) {
      plaintext =
          await sessionCipher.decryptFromSignal(ciphertext as SignalMessage);
    } else if (messageType == CiphertextMessage.senderKeyType) {
    } else if (messageType == CiphertextMessage.senderKeyDistributionType) {
    } else if (messageType == CiphertextMessage.encryptedMessageOverhead) {}
    if (plaintext == null) {
      throw '';
    }

    return plaintext;
  }

  close() async {}
}

class SignalSessionPool {
  late String peerId;
  late String clientId;
  int deviceId = 0;

  /// 本地的协议地址
  late SignalProtocolAddress signalProtocolAddress;

  ///本地的密钥对
  late SignalKeyPair signalKeyPair;

  Map<String, PreKeyBundle> retrievedPreKeys = {};

  ///加密会话的映射，key是对方的协议地址
  Map<SignalProtocolAddress, SignalSession> signalSessions = {};

  SignalSessionPool() {
    peerId = myself.peerId!;
    clientId = myself.clientId!;
    signalProtocolAddress =
        SignalProtocolAddress('$peerId:$clientId', deviceId);
  }

  init() async {
    signalKeyPair = SignalKeyPair();
    await signalKeyPair.init();
  }

  SignalSession create(
      {required String peerId,
      required clientId,
      int deviceId = 1,
      required retrievedPreKeyBundle}) {
    SignalSession? signalSession =
        get(peerId: peerId, clientId: clientId, deviceId: deviceId);
    if (signalSession != null) {
      return signalSession;
    }
    signalSession = SignalSession(
        peerId: peerId,
        clientId: clientId,
        deviceId: deviceId,
        retrievedPreKeyBundle: retrievedPreKeyBundle);
    var signalProtocolAddress =
        SignalProtocolAddress('$peerId:$clientId', deviceId);
    signalSessions[signalProtocolAddress] = signalSession;

    return signalSession;
  }

  SignalSession? get({
    required String peerId,
    required String clientId,
    int deviceId = 1,
  }) {
    var signalProtocolAddress =
        SignalProtocolAddress('$peerId:$clientId', deviceId);

    return signalSessions[signalProtocolAddress];
  }

  close({
    required String peerId,
    required String clientId,
    int deviceId = 1,
  }) {
    var signalProtocolAddress =
        SignalProtocolAddress('$peerId:$clientId', deviceId);
    signalSessions.remove(signalProtocolAddress);
  }
}

final SignalSessionPool signalSessionPool = SignalSessionPool();