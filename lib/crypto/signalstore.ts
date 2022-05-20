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
