import * as libsignal from '@privacyresearch/libsignal-protocol-typescript';
import * as util from '@privacyresearch/libsignal-protocol-typescript/lib/helpers';

// Type guards
export function isKeyPairType(kp: any): kp is libsignal.KeyPairType {
  return !!(kp.privKey && kp.pubKey);
}

export function isPreKeyType(pk: any): pk is libsignal.PreKeyPairType {
  return typeof pk.keyId === 'number' && isKeyPairType(pk.keyPair);
}

export function isSignedPreKeyType(spk: any): spk is libsignal.SignedPreKeyPairType {
  return spk.signature && isPreKeyType(spk);
}

interface KeyPairType {
  pubKey: ArrayBuffer;
  privKey: ArrayBuffer;
}

interface PreKeyType {
  keyId: number;
  keyPair: KeyPairType;
}

interface SignedPreKeyType extends PreKeyType {
  signature: ArrayBuffer;
}

function isArrayBuffer(thing: StoreValue): boolean {
  const t = typeof thing;
  return !!thing && t !== 'string' && t !== 'number' && 'byteLength' in (thing as any);
}

type StoreValue = KeyPairType | string | number | KeyPairType | PreKeyType | SignedPreKeyType | ArrayBuffer

export class SignalProtocolStore implements libsignal.StorageType {
  private _store: Record<string, StoreValue>;

  constructor() {
    this._store = {};
  }

  //
  get(key: string, defaultValue: StoreValue): StoreValue {
    if (key === null || key === undefined) throw new Error('Tried to get value for undefined/null key');
    if (key in this._store) {
      return this._store[key];
    } else {
      return defaultValue;
    }
  }

  remove(key: string): void {
    if (key === null || key === undefined) throw new Error('Tried to remove value for undefined/null key');
    delete this._store[key];
  }

  put(key: string, value: StoreValue): void {
    if (key === undefined || value === undefined || key === null || value === null)
      throw new Error('Tried to store undefined/null');
    this._store[key] = value;
  }

  async getIdentityKeyPair(): Promise<KeyPairType> {
    const kp = this.get('identityKey', undefined);
    if (isKeyPairType(kp) || typeof kp === 'undefined') {
      return kp;
    }
    throw new Error('Item stored as identity key of unknown type.');
  }

  async getLocalRegistrationId(): Promise<number> {
    const rid = this.get('registrationId', undefined);
    if (typeof rid === 'number' || typeof rid === 'undefined') {
      return rid;
    }
    throw new Error('Stored Registration ID is not a number');
  }

  isTrustedIdentity(
    identifier: string,
    identityKey: ArrayBuffer,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _direction: libsignal.Direction
  ): Promise<boolean> {
    if (identifier === null || identifier === undefined) {
      throw new Error('tried to check identity key for undefined/null key');
    }
    const trusted = this.get('identityKey' + identifier, undefined);

    // TODO: Is this right? If the ID is NOT in our store we trust it?
    if (trusted === undefined) {
      return Promise.resolve(true);
    }
    return Promise.resolve(
      util.arrayBufferToString(identityKey) === util.arrayBufferToString(trusted as ArrayBuffer)
    );
  }

  async loadPreKey(keyId: string | number): Promise<KeyPairType> {
    let res = this.get('25519KeypreKey' + keyId, undefined);
    if (isKeyPairType(res)) {
      res = {pubKey: res.pubKey, privKey: res.privKey};
      return res;
    } else if (typeof res === 'undefined') {
      return res;
    }
    throw new Error(`stored key has wrong type`);
  }

  async loadSession(identifier: string): Promise<libsignal.SessionRecordType> {
    const rec = this.get('session' + identifier, undefined);
    if (typeof rec === 'string') {
      return rec as string;
    } else if (typeof rec === 'undefined') {
      return rec;
    }
    throw new Error(`session record is not an ArrayBuffer`);
  }

  async loadSignedPreKey(keyId: number | string): Promise<KeyPairType> {
    const res = this.get('25519KeysignedKey' + keyId, undefined);
    if (isKeyPairType(res)) {
      return {pubKey: res.pubKey, privKey: res.privKey};
    } else if (typeof res === 'undefined') {
      return res;
    }
    throw new Error(`stored key has wrong type`);
  }

  async removePreKey(keyId: number | string): Promise<void> {
    //this.remove('25519KeypreKey' + keyId)
  }

  async saveIdentity(identifier: string, identityKey: ArrayBuffer): Promise<boolean> {
    if (identifier === null || identifier === undefined)
      throw new Error('Tried to put identity key for undefined/null key');

    const address = libsignal.SignalProtocolAddress.fromString(identifier);

    const existing = this.get('identityKey' + address.getName(), undefined);
    this.put('identityKey' + address.getName(), identityKey);
    if (existing && !isArrayBuffer(existing)) {
      throw new Error('Identity Key is incorrect type');
    }

    if (existing && util.arrayBufferToString(identityKey) !== util.arrayBufferToString(existing as ArrayBuffer)) {
      return true;
    } else {
      return false;
    }
  }

  async storeSession(identifier: string, record: libsignal.SessionRecordType): Promise<void> {
    return this.put('session' + identifier, record);
  }

  async loadIdentityKey(identifier: string): Promise<ArrayBuffer> {
    if (identifier === null || identifier === undefined) {
      throw new Error('Tried to get identity key for undefined/null key');
    }

    const key = this.get('identityKey' + identifier, undefined);
    if (isArrayBuffer(key)) {
      return key as ArrayBuffer;
    } else if (typeof key === 'undefined') {
      return key;
    }
    throw new Error(`Identity key has wrong type`);
  }

  async storePreKey(keyId: number | string, keyPair: KeyPairType): Promise<void> {
    return this.put('25519KeypreKey' + keyId, keyPair);
  }

  // TODO: Why is this keyId a number where others are strings?
  async storeSignedPreKey(keyId: number | string, keyPair: KeyPairType): Promise<void> {
    return this.put('25519KeysignedKey' + keyId, keyPair);
  }

  async removeSignedPreKey(keyId: number | string): Promise<void> {
    return this.remove('25519KeysignedKey' + keyId);
  }

  async removeSession(identifier: string): Promise<void> {
    return this.remove('session' + identifier);
  }

  async removeIdentity(identifier: string): Promise<void> {
    return this.remove('identityKey' + identifier);

  }

  async removeAllSessions(identifier: string): Promise<void> {
    for (const id in this._store) {
      if (id.startsWith('session' + identifier)) {
        delete this._store[id];
      }
    }
  }
}

export let signalProtocolStore = new SignalProtocolStore();


class SignalProtocol {
  late Map<String, String> signalPublicKeys ;
  late Map<String, SignalSession> signalSessions;
  late SignalKeyPair signalKeyPair ;
  late String name;
  int deviceId = 0;

  SignalProtocol() ;

  //初始化操作，在myself.SignalPrivateKey里面没有初始化的时候调用
   init() async{
    signalKeyPair = SignalKeyPair();
    signalKeyPair.registrationId = generateRegistrationId();
    signalProtocolStore.put(`registrationID`, this.signalKeyPair.registrationId);

    //完整的身份密钥和预设密钥，存入myself的privateKey字段，最好密码加密
    //系统启动时读取，不存在需要重新创建一个
    this.signalKeyPair.identityKey = await libsignal.KeyHelper.generateIdentityKeyPair();
    signalProtocolStore.put('identityKey', this.signalKeyPair.identityKey);

    const baseKeyId = 1;
    var preKey = await libsignal.KeyHelper.generatePreKey(baseKeyId);
    this.signalKeyPair.preKey = preKey;
    signalProtocolStore.storePreKey(`${baseKeyId}`, preKey.keyPair);

    const signedPreKeyId = 2;
    var signedPreKey = await libsignal.KeyHelper.generateSignedPreKey(this.signalKeyPair.identityKey, signedPreKeyId);
    this.signalKeyPair.signedPreKey = signedPreKey;
    signalProtocolStore.storeSignedPreKey(signedPreKeyId, signedPreKey.keyPair);

    this.signalSessions = new Map<string, SignalSession>();
    this.signalPublicKeys = new Map<string, string>();
  }

  //调用init后写入myself.SignalPrivateKey
  async export(password) {

    var signalKeyPair: any = Object.create(null);
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
    var buf = messageSerializer.marshal(signalKeyPair);
    buf = openpgp.compress(buf);
    var cipher = await openpgp.aesEncrypt(buf, password);
    var base64 = openpgp.encodeBase64(cipher);
    return base64;
  }

  //从myself.SignalPrivateKey里面初始化的时候调用
  async import(base64, password) {
    var cipher = openpgp.decodeBase64(base64);
    var buf = await openpgp.aesDecrypt(cipher, password);
    buf = openpgp.uncompress(buf);
    if (!this.signalKeyPair) {
      this.signalKeyPair = new SignalKeyPair();
      this.signalSessions = new Map<string, SignalSession>();
      this.signalPublicKeys = new Map<string, string>();
    }
    var signalKeyPair = messageSerializer.unmarshal(buf);
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
  async exportPublic(name): Promise<string> {
    // Now we register this with the server or other directory so all users can see them.
    // You might implement your directory differently, this is not part of the SDK.
    this.name = name;

    var signalPublicKey: any = Object.create(null);
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
    var buf = messageSerializer.marshal(signalPublicKey);
    buf = openpgp.compress(buf);
    var base64 = openpgp.encodeBase64(buf);

    return base64;
  }

  async importPublic(base64): Promise<SignalPublicKey> {
    var buf = openpgp.decodeBase64(base64);
    buf = openpgp.uncompress(buf);
    var signalPub = messageSerializer.unmarshal(buf);
    var signalPublicKey = new SignalPublicKey();
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
  async load(targetPeerId): Promise<SignalPublicKey> {
    // 从服务器的peerClient的publicKey字段解析
    var signalPublicKeyBase64 = this.signalPublicKeys.get(targetPeerId);
    if (signalPublicKeyBase64) {
      var signalPublicKey = await this.importPublic(signalPublicKeyBase64);
      return signalPublicKey;
    }
    return;
  }

  getKey(targetPeerId, clientId) {
    return targetPeerId + ":" + clientId;
  }

  async get(targetPeerId, clientId): Promise<SignalSession> {
    var key = this.getKey(targetPeerId, clientId);
    var signalSession = undefined;
    if (!this.signalSessions.has(key)) {
      // a SignalProtocolAddress
      this.deviceId++;
      var signalProtocolAddress = new libsignal.SignalProtocolAddress(key, this.deviceId);
      // Instantiate a SessionBuilder for a remote recipientId + deviceId tuple.
      var sessionBuilder = new libsignal.SessionBuilder(signalProtocolStore, signalProtocolAddress);
      // Process a prekey fetched from the server. Returns a promise that resolves
      // once a session is created and saved in the store, or rejects if the
      // identityKey differs from a previously seen identity for this address.
      var signalPublicKey = await this.load(targetPeerId);
      if (signalPublicKey) {
        var sessionType: libsignal.SessionType<ArrayBuffer> = await sessionBuilder.processPreKey(signalPublicKey);
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

  close(targetPeerId, clientId) {
    var key = this.getKey(targetPeerId, clientId);
    var signalSession = this.signalSessions.has(key);
    if (signalSession) {
      this.signalSessions.delete(key);
    }
  }

  getAll(): SignalSession[] {
    var signalSessions: SignalSession[] = [];
    for (var signalSession of signalProtocol.signalSessions.values()) {
      signalSessions.push(signalSession);
    }
    return signalSessions;
  }

  clear() {
    var signalSessions = this.getAll();
    for (var signalSession of signalSessions) {
      signalSession.close();
    }
  }
}

var signalProtocol = new SignalProtocol();
