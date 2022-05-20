import {openpgp} from '../crypto/openpgp';

/**
 * merkle hash树的实现
 */
class MerkleTree {
  constructor() {
  }

  /**
   * 构建merkle树.
   */
  async buildStringTree(data: string[]): Promise<string[]> {
    let hashList = new Array();
    if (data) {
      if (data.length > 1) {
        for (let i = 0; i < data.length; i = i + 2) {
          let d0 = data[i];
          let d1 = '';
          if (i < data.length - 1) {
            d1 = data[i + 1];
          }
          let hash = await this.buildString(d0, d1);
          hashList.push(hash);
        }
        if (hashList.length > 1) {
          let hashs = await this.buildStringTree(hashList);
          if (hashs && hashs.length > 0) {
            for (let hash of hashs) {
              hashList.push(hash);
            }
          }
        }
      } else {
        hashList.push(data[0]);
      }
    }

    return hashList;
  }

  async buildByteTree(data: Uint8Array[]): Promise<Uint8Array[]> {
    let hashList: Uint8Array[] = new Array();
    if (data && data.length > 1) {
      for (let i = 0; i < data.length; i = i + 2) {
        let d0 = data[i];
        let d1: Uint8Array;
        if (i < data.length - 1) {
          d1 = data[i + 1];
          let hash = await this.buildByte(d0, d1);
          hashList.push(hash);
        }
      }
      if (hashList.length > 1) {
        let hashs = await this.buildByteTree(hashList);
        if (hashs && hashs.length > 0) {
          for (let hash of hashs) {
            hashList.push(hash);
          }
        }
      }
    } else {
      hashList.push(data[0]);
    }

    return hashList;
  }

  async buildByte(hash1: Uint8Array, hash2: Uint8Array): Promise<Uint8Array> {
    let hash = await openpgp.hash(this.merge(hash1, hash2));
    return hash;
  }

  async buildString(hash1: string, hash2: string): Promise<Uint8Array> {
    let hash = await openpgp.hash(hash1 + hash2);
    return hash;
  }

  merge(hash1: Uint8Array, hash2: Uint8Array): Uint8Array {
    let hash = new Uint8Array(hash1.byteLength + hash2.byteLength);
    for (let i = 0; i < hash1.byteLength; i++) {
      hash[i] = hash1[i];
    }
    for (let i = 0; i < hash2.byteLength; i++) {
      hash[hash1.byteLength + i] = hash2[i];
    }

    return hash;
  }
}

export let merkleTree = new MerkleTree();
