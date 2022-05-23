import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../app.dart';

/// 协议的密钥对
class SignalKeyPair {
  late int registrationId;
  late IdentityKeyPair identityKeyPair;
  late List<PreKeyRecord> preKeys;
  late SignedPreKeyRecord signedPreKey;

  init() async {
    registrationId = generateRegistrationId(false);
    identityKeyPair = generateIdentityKeyPair();
    preKeys = generatePreKeys(0, 110);
    signedPreKey = generateSignedPreKey(identityKeyPair, 0);
  }
}

/// 协议密钥对产生的协议公钥
class SignalPublicKey {
  late PreKeyBundle retrievedPreKey;

  SignalPublicKey.fromPreKeyBundle(PreKeyBundle retrievedPreKey) {
    retrievedPreKey = retrievedPreKey;
  }

  ///根据绘画密钥对
  SignalPublicKey.fromSignalKeyPair(SignalKeyPair signalKeyPair) {
    retrievedPreKey = PreKeyBundle(
        signalKeyPair.registrationId,
        signalProtocol.deviceId,
        signalKeyPair.preKeys[0].id,
        signalKeyPair.preKeys[0].getKeyPair().publicKey,
        signalKeyPair.signedPreKey.id,
        signalKeyPair.signedPreKey.getKeyPair().publicKey,
        signalKeyPair.signedPreKey.signature,
        signalKeyPair.identityKeyPair.getPublicKey());
  }
}

/// 特定目标的signal加密会话，
/// 当与某个特定的节点的连接通道成功建立以后，就可以建立signal加密会话，然后进行消息的加解密
class SignalSession {
  late String targetPeerId;
  late String clientId;
  late int deviceId;
  late SignalProtocolAddress signalProtocolAddress;
  late SessionCipher sessionCipher;
  late PreKeyBundle retrievedPreKey;

  SignalSession(
      {required String targetPeerId,
      required String clientId,
      required String name,
      required int deviceId,
      required PreKeyBundle retrievedPreKey}) {
    targetPeerId = targetPeerId;
    clientId = clientId;
    var signalProtocolAddress = SignalProtocolAddress(name, deviceId);
    var sessionBuilder = SessionBuilder(
        signalProtocol.sessionStore,
        signalProtocol.preKeyStore,
        signalProtocol.signedPreKeyStore,
        signalProtocol.identityKeyStore,
        signalProtocolAddress);
    retrievedPreKey = retrievedPreKey;
    sessionBuilder.processPreKeyBundle(retrievedPreKey);
    sessionCipher = SessionCipher(
        signalProtocol.sessionStore,
        signalProtocol.preKeyStore,
        signalProtocol.signedPreKeyStore,
        signalProtocol.identityKeyStore,
        signalProtocolAddress);
  }

  Future<CiphertextMessage> encrypt(Uint8List data) async {
    var ciphertext = await sessionCipher.encrypt(data);

    return ciphertext;
  }

  Future<Uint8List> decrypt(CiphertextMessage ciphertext) async {
    var signalProtocolStore = signalProtocol.signalProtocolStore;
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

class SignalProtocol {
  late String clientId;
  late String name;
  int deviceId = 0;

  /// 本地的协议地址
  late SignalProtocolAddress signalProtocolAddress;

  ///本地的密钥对
  late SignalKeyPair signalKeyPair;

  ///本地的密钥对对应的公钥
  late SignalPublicKey signalPublicKey;

  ///本地的存储
  late InMemoryPreKeyStore preKeyStore;

  late InMemorySessionStore sessionStore;

  late InMemorySignedPreKeyStore signedPreKeyStore;

  late InMemoryIdentityKeyStore identityKeyStore;

  late InMemorySignalProtocolStore signalProtocolStore;

  Map<String, PreKeyBundle> retrievedPreKeys = {};
  Map<String, SignalSession> signalSessions = {};

  init() async {
    signalProtocolAddress = SignalProtocolAddress(name, deviceId);
    signalKeyPair = SignalKeyPair();
    signalPublicKey = SignalPublicKey.fromSignalKeyPair(signalKeyPair);

    signalProtocolStore = InMemorySignalProtocolStore(
        signalKeyPair.identityKeyPair, signalKeyPair.registrationId);
    sessionStore = signalProtocolStore.sessionStore;
    preKeyStore = signalProtocolStore.preKeyStore;
    signedPreKeyStore = signalProtocolStore.signedPreKeyStore;
    identityKeyStore = InMemoryIdentityKeyStore(
        signalKeyPair.identityKeyPair, signalKeyPair.registrationId);
    for (final p in signalKeyPair.preKeys) {
      await signalProtocolStore.storePreKey(p.id, p);
    }
    await signalProtocolStore.storeSignedPreKey(
        signalKeyPair.signedPreKey.id, signalKeyPair.signedPreKey);
  }

  export() {}

  import() {}
}

class GroupSession {
  late String name;
  late int deviceId = 0;

  GroupSession(String name) {
    name = name;
  }

  Future<Map<String, Object>> encrypt(
      List<int> message, String senderName) async {
    var senderAddress = SignalProtocolAddress(senderName, deviceId);
    var groupSender = SenderKeyName(name, senderAddress);

    final senderStore = InMemorySenderKeyStore();
    final senderSessionBuilder = GroupSessionBuilder(senderStore);
    final senderGroupCipher = GroupCipher(senderStore, groupSender);

    SenderKeyDistributionMessageWrapper sentDistributionMessage =
        await senderSessionBuilder.create(groupSender);
    SenderKeyDistributionMessageWrapper receivedDistributionMessage =
        SenderKeyDistributionMessageWrapper.fromSerialized(
            sentDistributionMessage.serialize());
    Uint8List ciphertextFromSender =
        await senderGroupCipher.encrypt(Uint8List.fromList(message));

    return {
      'distributionMessage': receivedDistributionMessage,
      'ciphertext': ciphertextFromSender
    };
  }

  Future<Uint8List> decrypt(
      SenderKeyDistributionMessageWrapper receivedDistributionMessage,
      Uint8List ciphertextFromSender,
      String senderName) async {
    var senderAddress = SignalProtocolAddress(senderName, deviceId);
    var groupSender = SenderKeyName(name, senderAddress);

    final bobStore = InMemorySenderKeyStore();
    final bobSessionBuilder = GroupSessionBuilder(bobStore);
    final bobGroupCipher = GroupCipher(bobStore, groupSender);
    await bobSessionBuilder.process(groupSender, receivedDistributionMessage);
    final plaintextFromAlice =
        await bobGroupCipher.decrypt(ciphertextFromSender);

    return plaintextFromAlice;
  }
}

final signalProtocol = SignalProtocol();
