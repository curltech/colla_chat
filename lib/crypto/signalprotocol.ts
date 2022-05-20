import * as libsignal from '@privacyresearch/libsignal-protocol-typescript';
import {signalProtocolStore} from './signalstore';
import {messageSerializer} from '@/libs/tool/message';
import {openpgp} from './openpgp';
import {TypeUtil} from '@/libs/tool/util';
import {logService} from '@/libs/biz/log';

/**
 * 特定目标的signal加密会话，
 * 当与某个特定的节点的连接通道成功建立以后，就可以建立signal加密会话，然后进行消息的加解密
 */
export class SignalSession {
  private targetPeerId: string;
  private clientId: string;
  private deviceId: number;
  private signalProtocolAddress: libsignal.SignalProtocolAddress;
  private sessionCipher: libsignal.SessionCipher;

  constructor(signalProtocolAddress: libsignal.SignalProtocolAddress) {
    this.signalProtocolAddress = signalProtocolAddress;
    this.sessionCipher = new libsignal.SessionCipher(signalProtocolStore, this.signalProtocolAddress);
  }

  set(targetPeerId: string, clientId: string, deviceId: number) {
    this.deviceId = deviceId;
    this.targetPeerId = targetPeerId;
    this.clientId = clientId;
  }

  async encrypt(data: Uint8Array | string): Promise<libsignal.MessageType> {
    let buffer: ArrayBuffer;
    if (TypeUtil.isString(data)) {
      let msg: string = <string>data;
      buffer = new TextEncoder().encode(msg).buffer;
    } else {
      let buf: Uint8Array = <Uint8Array>data;
      buffer = buf.buffer;
    }
    let ciphertext = await this.sessionCipher.encrypt(buffer);

    return ciphertext;
  }

  async decrypt(ciphertext: libsignal.MessageType, option: string = 'binary'): Promise<string | Uint8Array> {
    // Decrypting a PreKeyWhisperMessage will establish a new session and
    // store it in the SignalProtocolStore. It returns a promise that resolves
    // when the message is decrypted or rejects if the identityKey differs from
    // a previously seen identity for this address.
    let plaintext: ArrayBuffer;
    // ciphertext: MessageType
    if (ciphertext.type === 3) {
      // It is a PreKeyWhisperMessage and will establish a session.
      try {
        plaintext = await this.sessionCipher.decryptPreKeyWhisperMessage(ciphertext.body!, 'binary');
      } catch (e: any) {
        console.log(e);
        await logService.log(e, 'signalDecryptError', 'error');

      }
    } else if (ciphertext.type === 1) {
      // It is a WhisperMessage for an established session.
      plaintext = await this.sessionCipher.decryptWhisperMessage(ciphertext.body!, 'binary');
    }

    // now you can do something with your plaintext, like
    // @ts-ignore
    let buf = new Uint8Array(plaintext);
    if (option === 'binary') {
      return buf;
    }
    let msg = new TextDecoder().decode(buf);

    return msg;
  }

  async close() {
    await this.sessionCipher.closeOpenSessionForDevice();
    await this.sessionCipher.deleteAllSessionsForDevice();
    signalProtocol.close(this.targetPeerId, this.clientId);
    let identifier = this.signalProtocolAddress.getName();
    signalProtocolStore.removeSession(identifier);
    //signalProtocolStore.removeIdentity(identifier)
  }
}

class SignalKeyPair {
  public registrationId: number;
  public identityKey: libsignal.KeyPairType<ArrayBuffer>;
  public signedPreKey: libsignal.SignedPreKeyPairType<ArrayBuffer>;
  public preKey: libsignal.PreKeyPairType<ArrayBuffer>;
}

class SignalPublicKey implements libsignal.DeviceType<ArrayBuffer> {
  public registrationId: number;
  public identityKey: ArrayBuffer;
  public signedPreKey: libsignal.SignedPublicPreKeyType;
  public preKey: libsignal.PreKeyType;
}

export class SignalProtocol {
  public signalPublicKeys: Map<string, string>;
  public signalSessions: Map<string, SignalSession>;
  private signalKeyPair: SignalKeyPair;
  private name: string;
  private deviceId: number = 0;

  constructor() {
  }

  //初始化操作，在myself.SignalPrivateKey里面没有初始化的时候调用
  async init() {
    this.signalKeyPair = new SignalKeyPair();
    this.signalKeyPair.registrationId = libsignal.KeyHelper.generateRegistrationId();
    signalProtocolStore.put(`registrationID`, this.signalKeyPair.registrationId);

    //完整的身份密钥和预设密钥，存入myself的privateKey字段，最好密码加密
    //系统启动时读取，不存在需要重新创建一个
    this.signalKeyPair.identityKey = await libsignal.KeyHelper.generateIdentityKeyPair();
    signalProtocolStore.put('identityKey', this.signalKeyPair.identityKey);

    const baseKeyId = 1;
    let preKey = await libsignal.KeyHelper.generatePreKey(baseKeyId);
    this.signalKeyPair.preKey = preKey;
    signalProtocolStore.storePreKey(`${baseKeyId}`, preKey.keyPair);

    const signedPreKeyId = 2;
    let signedPreKey = await libsignal.KeyHelper.generateSignedPreKey(this.signalKeyPair.identityKey, signedPreKeyId);
    this.signalKeyPair.signedPreKey = signedPreKey;
    signalProtocolStore.storeSignedPreKey(signedPreKeyId, signedPreKey.keyPair);

    this.signalSessions = new Map<string, SignalSession>();
    this.signalPublicKeys = new Map<string, string>();
  }

  //调用init后写入myself.SignalPrivateKey
  async export(password: string) {

    let signalKeyPair: any = Object.create(null);
    signalKeyPair.registrationId = this.signalKeyPair.registrationId;
    signalKeyPair.identityKey = {
      pubKey: messageSerializer.arrayBufferToString(this.signalKeyPair.identityKey.pubKey),
      privKey: messageSerializer.arrayBufferToString(this.signalKeyPair.identityKey.privKey)
    };
    signalKeyPair.signedPreKey = {
      keyId: this.signalKeyPair.signedPreKey.keyId,
      keyPair: {
        pubKey: messageSerializer.arrayBufferToString(this.signalKeyPair.signedPreKey.keyPair.pubKey),
        privKey: messageSerializer.arrayBufferToString(this.signalKeyPair.signedPreKey.keyPair.privKey),
      },
      signature: messageSerializer.arrayBufferToString(this.signalKeyPair.signedPreKey.signature),
    };
    signalKeyPair.preKey = {
      keyId: this.signalKeyPair.preKey.keyId,
      keyPair: {
        pubKey: messageSerializer.arrayBufferToString(this.signalKeyPair.preKey.keyPair.pubKey),
        privKey: messageSerializer.arrayBufferToString(this.signalKeyPair.preKey.keyPair.privKey)
      }
    };
    let buf = messageSerializer.marshal(signalKeyPair);
    buf = openpgp.compress(buf);
    let cipher = await openpgp.aesEncrypt(buf, password);
    let base64 = openpgp.encodeBase64(cipher);
    return base64;
  }

  //从myself.SignalPrivateKey里面初始化的时候调用
  async import(base64: string, password: string) {
    let cipher = openpgp.decodeBase64(base64);
    let buf = await openpgp.aesDecrypt(cipher, password);
    buf = openpgp.uncompress(buf);
    if (!this.signalKeyPair) {
      this.signalKeyPair = new SignalKeyPair();
      this.signalSessions = new Map<string, SignalSession>();
      this.signalPublicKeys = new Map<string, string>();
    }
    let signalKeyPair = messageSerializer.unmarshal(buf);
    signalKeyPair.identityKey.pubKey = messageSerializer.stringToArrayBuffer(signalKeyPair.identityKey.pubKey);
    signalKeyPair.identityKey.privKey = messageSerializer.stringToArrayBuffer(signalKeyPair.identityKey.privKey);

    signalKeyPair.signedPreKey.keyPair.pubKey = messageSerializer.stringToArrayBuffer(signalKeyPair.signedPreKey.keyPair.pubKey);
    signalKeyPair.signedPreKey.keyPair.privKey = messageSerializer.stringToArrayBuffer(signalKeyPair.signedPreKey.keyPair.privKey);

    signalKeyPair.preKey.keyPair.pubKey = messageSerializer.stringToArrayBuffer(signalKeyPair.preKey.keyPair.pubKey);
    signalKeyPair.preKey.keyPair.privKey = messageSerializer.stringToArrayBuffer(signalKeyPair.preKey.keyPair.privKey);

    this.signalKeyPair.registrationId = signalKeyPair.registrationId;
    this.signalKeyPair.identityKey = signalKeyPair.identityKey;
    this.signalKeyPair.preKey = signalKeyPair.preKey;
    this.signalKeyPair.signedPreKey = signalKeyPair.signedPreKey;


    signalProtocolStore.put(`registrationID`, this.signalKeyPair.registrationId);
    signalProtocolStore.put('identityKey', this.signalKeyPair.identityKey);

    const baseKeyId = 1;
    signalProtocolStore.storePreKey(`${baseKeyId}`, this.signalKeyPair.preKey.keyPair);

    const signedPreKeyId = 2;
    signalProtocolStore.storeSignedPreKey(signedPreKeyId, this.signalKeyPair.signedPreKey.keyPair);
  }

  //把自己的密钥的公钥部分存入peerClient并上传到服务器
  async exportPublic(name: string): Promise<string> {
    // Now we register this with the server or other directory so all users can see them.
    // You might implement your directory differently, this is not part of the SDK.
    this.name = name;

    let signalPublicKey: any = Object.create(null);
    signalPublicKey.registrationId = this.signalKeyPair.registrationId;
    signalPublicKey.identityKey = messageSerializer.arrayBufferToString(this.signalKeyPair.identityKey.pubKey);
    signalPublicKey.signedPreKey = {
      keyId: this.signalKeyPair.signedPreKey.keyId,
      publicKey: messageSerializer.arrayBufferToString(this.signalKeyPair.signedPreKey.keyPair.pubKey),
      signature: messageSerializer.arrayBufferToString(this.signalKeyPair.signedPreKey.signature)
    };
    signalPublicKey.preKey = {
      keyId: this.signalKeyPair.preKey.keyId,
      publicKey: messageSerializer.arrayBufferToString(this.signalKeyPair.preKey.keyPair.pubKey)
    };
    // json化后调用putClient放入服务器的publicKey字段
    let buf = messageSerializer.marshal(signalPublicKey);
    buf = openpgp.compress(buf);
    let base64 = openpgp.encodeBase64(buf);

    return base64;
  }

  async importPublic(base64: string): Promise<SignalPublicKey> {
    let buf = openpgp.decodeBase64(base64);
    buf = openpgp.uncompress(buf);
    let signalPub = messageSerializer.unmarshal(buf);
    let signalPublicKey = new SignalPublicKey();
    signalPublicKey.registrationId = signalPub.registrationId;
    signalPublicKey.identityKey = messageSerializer.stringToArrayBuffer(signalPub.identityKey);
    signalPublicKey.preKey = signalPub.preKey;
    signalPublicKey.preKey.publicKey = messageSerializer.stringToArrayBuffer(signalPub.preKey.publicKey);
    signalPublicKey.signedPreKey = signalPub.signedPreKey;
    signalPublicKey.signedPreKey.publicKey = messageSerializer.stringToArrayBuffer(signalPub.signedPreKey.publicKey);
    signalPublicKey.signedPreKey.signature = messageSerializer.stringToArrayBuffer(signalPub.signedPreKey.signature);
    return signalPublicKey;
  }

  /**
   * 加载目标对象的预设公钥
   * @param targetPeerId
   */
  async load(targetPeerId: string): Promise<SignalPublicKey> {
    // 从服务器的peerClient的publicKey字段解析
    let signalPublicKeyBase64: string = this.signalPublicKeys.get(targetPeerId);
    if (signalPublicKeyBase64) {
      let signalPublicKey = await this.importPublic(signalPublicKeyBase64);
      return signalPublicKey;
    }
    return;
  }

  getKey(targetPeerId: string, clientId: string): string {
    return targetPeerId + ":" + clientId;
  }

  async get(targetPeerId: string, clientId: string): Promise<SignalSession> {
    let key = this.getKey(targetPeerId, clientId);
    let signalSession = undefined;
    if (!this.signalSessions.has(key)) {
      // a SignalProtocolAddress
      this.deviceId++;
      let signalProtocolAddress = new libsignal.SignalProtocolAddress(key, this.deviceId);
      // Instantiate a SessionBuilder for a remote recipientId + deviceId tuple.
      let sessionBuilder = new libsignal.SessionBuilder(signalProtocolStore, signalProtocolAddress);
      // Process a prekey fetched from the server. Returns a promise that resolves
      // once a session is created and saved in the store, or rejects if the
      // identityKey differs from a previously seen identity for this address.
      let signalPublicKey = await this.load(targetPeerId);
      if (signalPublicKey) {
        let sessionType: libsignal.SessionType<ArrayBuffer> = await sessionBuilder.processPreKey(signalPublicKey);
        if (sessionType) {
          signalSession = new SignalSession(signalProtocolAddress);
          signalSession.set(targetPeerId, clientId, this.deviceId);
          this.signalSessions.set(key, signalSession);
        }
      }
    } else {
      signalSession = this.signalSessions.get(key);
    }
    return signalSession;
  }

  close(targetPeerId: string, clientId: string) {
    let key = this.getKey(targetPeerId, clientId);
    let signalSession = this.signalSessions.has(key);
    if (signalSession) {
      this.signalSessions.delete(key);
    }
  }

  getAll(): SignalSession[] {
    let signalSessions: SignalSession[] = [];
    for (let signalSession of signalProtocol.signalSessions.values()) {
      signalSessions.push(signalSession);
    }
    return signalSessions;
  }

  clear() {
    let signalSessions = this.getAll();
    for (let signalSession of signalSessions) {
      signalSession.close();
    }
  }
}

export let signalProtocol = new SignalProtocol();
