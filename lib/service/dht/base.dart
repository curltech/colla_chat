import '../../entity/base.dart';
import '../base.dart';

abstract class PeerEntityService extends BaseService {
  Future<List<Map>> findByPeerId(String peerId) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    var peers = await find(where, whereArgs: whereArgs);

    return peers;
  }

  Future<Map?> findOneEffectiveByPeerId(String peerId) async {
    var peers = await findByPeerId(peerId);
    if (peers.isNotEmpty) {
      for (var peer in peers) {
        if (peer['status'] == EntityStatus.Effective.toString()) {
          return peer;
        }
      }
    }

    return null;
  }

  Future<List<Map>> findByName(String name) async {
    var where = 'name = ?';
    var whereArgs = [name];
    var peers = await find(where, whereArgs: whereArgs);

    return peers;
  }

  Future<Map?> findOneEffectiveByName(String name) async {
    var peers = await findByName(name);
    if (peers.isNotEmpty) {
      for (var peer in peers) {
        if (peer['status'] == EntityStatus.Effective.toString()) {
          return peer;
        }
      }
    }

    return null;
  }
}

class MyselfService{

  Future<Myself> initMyself(String password, MyselfPeer myselfPeer) async{
    if (myselfPeer==null) {
      throw 'NoMyselfPeer';
    }
    if (myselfPeer.name==null) {
      throw 'NoMyselfPeerName';
    }
    if (password==null) {
      throw 'NoPassword';
    }
    /**
        perrId对应的密钥对
     */
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
    SimplePublicKey publicKey = await peerPrivateKey.extractPublicKey();
    myselfPeer.peerPrivateKey = await cryptoGraphy.export(peerPrivateKey,passphrase:password.codeUnits);
    myselfPeer.peerPublicKey = await cryptoGraphy.export(peerPrivateKey);
    var peerId = await cryptoGraphy.export(peerPrivateKey,base: '58');
    myselfPeer.peerId = peerId;
    /**
        加密对应的密钥对x25519
     */
    var keyPair = await cryptoGraphy.generateKeyPair(keyPairType:'x25519');
    myselfPeer.privateKey = await cryptoGraphy.export(keyPair,passphrase:password.codeUnits);
    myselfPeer.publicKey = await cryptoGraphy.export(keyPair);

    myself.myselfPeer = myselfPeer;
    myself.password = password;
    myself.peerPrivateKey = peerPrivateKey;
    myself.peerPublicKey = publicKey;
    myself.privateKey = keyPair;
    myself.publicKey = await keyPair.extractPublicKey();

    return myself;
  }

  /// 获取自己节点的记录，并解开私钥
  Future<Myself> getMyself(String password, String peerId, String mobile, String name)  async {
    if (password==null) {
      throw 'NoPassword';
    }
    if (peerId==null && mobile==null && name==null) {
      throw 'NoPeerIdAndMobileAndName';
    }
    var where = 'status =? ';
    var whereArgs=[EntityStatus.Effective.toString()];
    if (peerId) {
      param.peerId = peerId;
    }
    if (mobile) {
      param.mobile = mobile;
    }
    if (name) {
      param.name = name;
    }
    var myselfPeer = await myselfPeerService.findOne(param, null, null);
    if (!myselfPeer) {
      throw new Error("AccountNotExists");
    }
    if (!myselfPeer.peerId) {
      console.error('!myselfPeer.peerId');
      throw new Error("InvalidAccount");
    }
    if (!peerId) {
      peerId = myselfPeer.peerId;
    }
    var publicKey = await openpgp.import(myselfPeer.publicKey);
    var buf = openpgp.decodeBase64(myselfPeer.peerPublicKey);
    var pub = await libp2pcrypto.keys.unmarshalPublicKey(buf);
    var privateKey = null;
    var priv = null;
    try {
      privateKey = await openpgp.import(myselfPeer.privateKey, {password: password});
      if (!privateKey) {
        console.error('!import(myselfPeer.privateKey)');
        throw new Error("InvalidAccount");
      }
      var isDecrypted = privateKey.isDecrypted();
      console.log('isDecrypted:' + isDecrypted);
      if (!isDecrypted) {
        await privateKey.decrypt(password);
      }
      priv = await libp2pcrypto.keys.import(myselfPeer.peerPrivateKey, password);
    } catch (e) {
      console.error(e);
      throw new Error('WrongPassword');
    }
    this.peerId = await PeerId.createFromPrivKey(priv.bytes);
    if (peerId !== this.peerId.toB58String()) {
    console.error('peerId !== PeerId.createFromPrivKey(priv.bytes).toB58String()');
    throw new Error("InvalidAccount");
    }
    var timestamp_ = new Date().getTime();
    var random_ = await openpgp.getRandomAsciiString();
    var key = timestamp_ + random_;
    var signature = await openpgp.sign(key, privateKey);
    var pass = await openpgp.verify(key, signature, publicKey);
    if (!pass) {
    throw new Error('VerifyNotPass');
    }
    param = {status: EntityStatus[EntityStatus.Effective]};
    param.peerId = peerId;
    var peerProfile = await peerProfileService.findOne(param, null, null);

    myself.myselfPeer = myselfPeer;
    myself.peerProfile = peerProfile;
    myself.password = password;
    myself.peerPrivateKey = priv;
    myself.peerPublicKey = pub;
    myself.privateKey = privateKey;
    myself.publicKey = publicKey;

    return myself;
  }

  upsertMyselfPeer() {
    var myselfPeer = myself.myselfPeer;
    var id: number = myselfPeer._id;
    if (!id) { //新的
    myselfPeer.status = EntityStatus[EntityStatus.Effective];
    var saddrs = this.host.addressManager.getListenAddrs();
    myselfPeer.address = JSON.stringify(saddrs);
    myselfPeer = myselfPeerService.insert(myselfPeer);
    } else {
    var needUpdate = false;
    var saddrs = this.host.addressManager.getListenAddrs();
    var addrs: string = JSON.stringify(saddrs);
    console.log('address:' + addrs);
    if (myselfPeer.address !== addrs) {
    needUpdate = true;
    myselfPeer.address = addrs;
    }

    if (needUpdate === true) {
    myselfPeer = myselfPeerService.update(myselfPeer);
    }
    }
    myself.myselfPeer = myselfPeer;
  }
}
