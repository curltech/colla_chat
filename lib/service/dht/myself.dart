import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:cryptography/cryptography.dart';

import '../../crypto/cryptography.dart';
import '../../entity/dht/myself.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../provider/app_data_provider.dart';
import '../../tool/util.dart';
import '../../transport/webrtc/peer_connection_pool.dart';
import '../../widgets/common/image_widget.dart';

class MyselfService {
  ///创建新的myself，创建新的密钥对，设置到当前
  createMyself(MyselfPeer myselfPeer, String password) async {
    ///peerId对应的密钥对
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
    SimplePublicKey peerPublicKey = await peerPrivateKey.extractPublicKey();
    myselfPeer.peerPrivateKey =
        await cryptoGraphy.export(peerPrivateKey, password.codeUnits);
    myselfPeer.peerPublicKey =
        await cryptoGraphy.exportPublicKey(peerPrivateKey);
    myselfPeer.peerId = myselfPeer.peerPublicKey;

    ///加密对应的密钥对x25519
    SimpleKeyPair keyPair =
        await cryptoGraphy.generateKeyPair(keyPairType: KeyPairType.x25519);
    SimplePublicKey publicKey = await keyPair.extractPublicKey();
    myselfPeer.privateKey =
        await cryptoGraphy.export(keyPair, password.codeUnits);
    myselfPeer.publicKey = await cryptoGraphy.exportPublicKey(keyPair);

    myself.myselfPeer = myselfPeer;
    myself.password = password;
    myself.peerPrivateKey = peerPrivateKey;
    myself.peerPublicKey = peerPublicKey;
    myself.privateKey = keyPair;
    myself.publicKey = publicKey;
  }

  /// 获取自己节点的记录，并解开私钥，设置当前myself
  /// 一般发生在登录后重新设置当前的账户
  Future<bool> login(MyselfPeer myselfPeer, String password) async {
    //解开身份公钥和加密公钥
    SimplePublicKey publicKey = await cryptoGraphy
        .importPublicKey(myselfPeer.publicKey, type: KeyPairType.x25519);
    SimplePublicKey peerPublicKey =
        await cryptoGraphy.importPublicKey(myselfPeer.peerPublicKey);
    //解开身份密钥对和加密密钥对
    SimpleKeyPair privateKey = await cryptoGraphy.import(
        myselfPeer.privateKey, password.codeUnits, publicKey,
        type: KeyPairType.x25519);
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.import(
        myselfPeer.peerPrivateKey, password.codeUnits, peerPublicKey);

    //检查身份密钥对，如果通过，设置本地myself的属性
    var timestamp_ = DateUtil.currentDate();
    var random_ = await cryptoGraphy.getRandomAsciiString();
    var key = timestamp_ + random_;
    var signature = await cryptoGraphy.sign(key.codeUnits, peerPrivateKey);
    bool pass = await cryptoGraphy.verify(key.codeUnits, signature,
        publicKey: peerPublicKey);
    if (!pass) {
      logger.e('VerifyNotPass');
      return false;
    }

    myself.myselfPeer = myselfPeer;
    myself.peerId = myselfPeer.peerId;
    myself.clientId = myselfPeer.clientId;
    myself.password = password;
    myself.peerPrivateKey = peerPrivateKey;
    myself.peerPublicKey = peerPublicKey;
    myself.privateKey = privateKey;
    myself.publicKey = publicKey;

    //查找配置信息
    var peerId = myselfPeer.peerId;
    var peerProfile = await peerProfileService.findOneByPeerId(peerId);
    if (peerProfile != null) {
      myself.peerProfile = peerProfile;
      String? avatar = peerProfile.avatar;
      var avatarImage = ImageWidget(
        image: avatar,
        height: 32,
        width: 32,
      );
      myself.avatarImage = avatarImage;
    }

    return true;
  }

  bool logout() {
    myself.myselfPeer = null;
    myself.password = null;
    myself.peerPrivateKey = null;
    myself.peerPublicKey = null;
    myself.privateKey = null;
    myself.publicKey = null;

    return true;
  }
}

final myselfService = MyselfService();
