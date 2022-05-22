import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:cryptography/cryptography.dart';

import '../../app.dart';
import '../../crypto/cryptography.dart';
import '../../entity/base.dart';
import '../../entity/dht/base.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../entity/dht/peerprofile.dart';
import '../../tool/util.dart';
import '../base.dart';
import 'myselfpeer.dart';

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

class MyselfService {
  Future<Myself> initMyself(String password, MyselfPeer myselfPeer) async {
    if (myselfPeer == null) {
      throw 'NoMyselfPeer';
    }
    if (myselfPeer.name == null) {
      throw 'NoMyselfPeerName';
    }
    if (password == null) {
      throw 'NoPassword';
    }
    /**
        perrId对应的密钥对
     */
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
    SimplePublicKey publicKey = await peerPrivateKey.extractPublicKey();
    myselfPeer.peerPrivateKey = await cryptoGraphy.export(peerPrivateKey,
        passphrase: password.codeUnits);
    myselfPeer.peerPublicKey = await cryptoGraphy.export(peerPrivateKey);
    var peerId = await cryptoGraphy.export(peerPrivateKey, base: '58');
    myselfPeer.peerId = peerId;
    /**
        加密对应的密钥对x25519
     */
    var keyPair = await cryptoGraphy.generateKeyPair(keyPairType: 'x25519');
    myselfPeer.privateKey =
        await cryptoGraphy.export(keyPair, passphrase: password.codeUnits);
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
  Future<Myself> getMyself(
      String password, String peerId, String mobile, String name) async {
    if (password == null) {
      throw 'NoPassword';
    }
    if (peerId == null && mobile == null && name == null) {
      throw 'NoPeerIdAndMobileAndName';
    }
    var myselfPeer = await myselfPeerService.findOneEffectiveByPeerId(peerId);
    if (myselfPeer == null) {
      throw 'AccountNotExists';
    }
    var publicKey = await cryptoGraphy.import(myselfPeer.publicKey);
    var buf = CryptoUtil.decodeBase64(myselfPeer.peerPublicKey);
    var pub = await libp2pcrypto.keys.unmarshalPublicKey(buf);
    var privateKey = null;
    var priv = null;
    try {
      privateKey = await cryptoGraphy
          .import(myselfPeer.privateKey, {password: password});
      if (!privateKey) {
        console.error('!import(myselfPeer.privateKey)');
        throw new Error("InvalidAccount");
      }
      var isDecrypted = privateKey.isDecrypted();
      logger.i('isDecrypted:$isDecrypted');
      if (!isDecrypted) {
        await privateKey.decrypt(password);
      }
      priv =
          await libp2pcrypto.keys.import(myselfPeer.peerPrivateKey, password);
    } catch (e) {
      logger.e(e);
      throw 'WrongPassword';
    }
    this.peerId = await PeerId.createFromPrivKey(priv.bytes);
    if (peerId != this.peerId.toB58String()) {
      logger.e('peerId !== PeerId.createFromPrivKey(priv.bytes).toB58String()');
      throw 'InvalidAccount';
    }
    var timestamp_ = DateTime.now().microsecondsSinceEpoch;
    var random_ = await cryptoGraphy.getRandomAsciiString();
    var key = timestamp_ + random_;
    var signature = await cryptoGraphy.sign(key, privateKey);
    bool pass = await cryptoGraphy.verify(key, signature, publicKey);
    if (!pass) {
      throw 'VerifyNotPass';
    }
    var peerProfile =
        await PeerProfileService.instance.findOneEffectiveByPeerId(peerId);

    myself.myselfPeer = myselfPeer;
    myself.peerProfile = PeerProfile.fromJson(peerProfile);
    myself.password = password;
    myself.peerPrivateKey = priv;
    myself.peerPublicKey = pub;
    myself.privateKey = privateKey;
    myself.publicKey = publicKey;

    return myself;
  }

  upsertMyselfPeer() async {
    var myselfPeer = myself.myselfPeer;
    int? id = myselfPeer.id;
    var myselfPeerService = MyselfPeerService.instance;
    if (id == null) {
      //新的
      myselfPeer.status = EntityStatus.Effective.toString();
      var saddrs = await NetworkInfoUtil.getWifiIp();
      myselfPeer.address = saddrs;
      myselfPeer = (await myselfPeerService.insert(myselfPeer)) as MyselfPeer;
    } else {
      var needUpdate = false;
      var addrs = await NetworkInfoUtil.getWifiIp();
      logger.i('address:$addrs');
      if (myselfPeer.address != addrs) {
        needUpdate = true;
        myselfPeer.address = addrs;
      }

      if (needUpdate) {
        myselfPeer = (await myselfPeerService.update(myselfPeer)) as MyselfPeer;
      }
    }
    myself.myselfPeer = myselfPeer;
  }
}
