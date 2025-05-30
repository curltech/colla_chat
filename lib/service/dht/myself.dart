import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

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
    myselfPeer.peerId = myselfPeer.peerPublicKey!;
    myselfPeer.ownerPeerId = myselfPeer.peerId;

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

  updateMyselfPassword(MyselfPeer myselfPeer, String password) async {
    ///peerId对应的密钥对
    SimpleKeyPair? peerPrivateKey = myself.peerPrivateKey;
    myselfPeer.peerPrivateKey =
        await cryptoGraphy.export(peerPrivateKey!, password.codeUnits);

    ///加密对应的密钥对x25519
    SimpleKeyPair? keyPair = myself.privateKey;
    myselfPeer.privateKey =
        await cryptoGraphy.export(keyPair!, password.codeUnits);
    myself.password = password;
  }

  /// 获取自己节点的记录，并解开私钥，进行验证
  Future<String?> auth(MyselfPeer myselfPeer, String password) async {
    //解开身份公钥和加密公钥
    SimplePublicKey? publicKey = await cryptoGraphy
        .importPublicKey(myselfPeer.publicKey!, type: KeyPairType.x25519);
    SimplePublicKey? peerPublicKey =
        await cryptoGraphy.importPublicKey(myselfPeer.peerPublicKey!);
    //解开身份密钥对和加密密钥对
    if (publicKey == null) {
      logger.e('publicKey is null');
      return 'publicKey is null';
    }
    SimpleKeyPair privateKey = await cryptoGraphy.import(
        myselfPeer.privateKey, password.codeUnits, publicKey,
        type: KeyPairType.x25519);
    if (peerPublicKey == null) {
      logger.e('peerPublicKey is null');
      return 'peerPublicKey is null';
    }
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.import(
        myselfPeer.peerPrivateKey, password.codeUnits, peerPublicKey);

    //检查身份密钥对
    var timestamp_ = DateUtil.currentDate();
    var random_ = await cryptoGraphy.getRandomAsciiString();
    var key = timestamp_ + random_;
    var signature = await cryptoGraphy.sign(key.codeUnits, peerPrivateKey);
    bool pass = await cryptoGraphy.verify(key.codeUnits, signature,
        publicKey: peerPublicKey);
    if (!pass) {
      logger.e('Verify not pass');
      return 'Verify not pass';
    }

    return null;
  }

  /// 获取自己节点的记录，并解开私钥，设置当前myself
  /// 一般发生在登录后重新设置当前的账户
  Future<String?> login(MyselfPeer myselfPeer, String password) async {
    //解开身份公钥和加密公钥
    SimplePublicKey? publicKey = await cryptoGraphy
        .importPublicKey(myselfPeer.publicKey!, type: KeyPairType.x25519);
    SimplePublicKey? peerPublicKey =
        await cryptoGraphy.importPublicKey(myselfPeer.peerPublicKey!);
    //解开身份密钥对和加密密钥对
    if (publicKey == null) {
      logger.e('publicKey is null');
      return 'publicKey is null';
    }
    SimpleKeyPair? privateKey = await cryptoGraphy.import(
        myselfPeer.privateKey, password.codeUnits, publicKey,
        type: KeyPairType.x25519);
    if (peerPublicKey == null) {
      logger.e('peerPublicKey is null');
      return 'peerPublicKey is null';
    }
    SimpleKeyPair? peerPrivateKey = await cryptoGraphy.import(
        myselfPeer.peerPrivateKey, password.codeUnits, peerPublicKey);
    //检查身份密钥对，如果通过，设置本地myself的属性
    var timestamp_ = DateUtil.currentDate();
    var random_ = await cryptoGraphy.getRandomAsciiString();
    var key = timestamp_ + random_;
    var signature = await cryptoGraphy.sign(key.codeUnits, peerPrivateKey);
    bool pass = await cryptoGraphy.verify(key.codeUnits, signature,
        publicKey: peerPublicKey);
    if (!pass) {
      logger.e('Verify not pass');
      return 'Verify not pass';
    }
    myself.myselfPeer = myselfPeer;
    myself.id = myselfPeer.id;
    myself.peerId = myselfPeer.peerId;
    myself.name = myselfPeer.name;
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
      if (myself.locale == platformParams.locale) {
        myself.locale = LocaleUtil.getLocale(peerProfile.locale);
      }
      String? avatar = myselfPeer.avatar;
      if (avatar != null) {
        var avatarImage = ImageUtil.buildImageWidget(
            imageContent: avatar,
            height: AppImageSize.mdSize,
            width: AppImageSize.mdSize,
            fit: BoxFit.contain);
        myselfPeer.avatarImage = avatarImage;

        var avatarIcon = ImageIcon(
          AssetImage(
            avatar,
          ),
          size: AppImageSize.mdSize,
        );
        myselfPeer.avatarIcon = avatarIcon;
      }
    }

    return null;
  }

  bool logout() {
    myself.myselfPeer = MyselfPeer('', '', '', '');
    myself.peerProfile = PeerProfile('');
    if (myself.locale != platformParams.locale) {
      myself.locale = platformParams.locale;
    }
    myself.id = null;
    myself.peerId = null;
    myself.name = null;
    myself.clientId = null;
    myself.password = null;
    myself.peerPrivateKey = null;
    myself.peerPublicKey = null;
    myself.privateKey = null;
    myself.publicKey = null;
    logger.clearMyLogger();
    linkmanService.linkmen.clear();
    peerClientService.peerClients.clear();
    groupService.groups.clear();
    conferenceService.conferences.clear();

    return true;
  }
}

final myselfService = MyselfService();
