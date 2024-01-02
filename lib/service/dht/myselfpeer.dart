import 'dart:async';
import 'dart:io';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/base.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/action/connect.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/background/android_backgroud_service.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/plugin/notification/firebase_messaging_service.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/base.dart';
import 'package:colla_chat/service/dht/myself.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/network_connectivity.dart';
import 'package:colla_chat/tool/phone_number_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

const String autoLoginName = 'autoLogin';
const String lastLoginName = 'lastLogin';
const String credentialName = 'credential';
const String passwordName = 'password';

class MyselfPeerService extends PeerEntityService<MyselfPeer> {
  MyselfPeerService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return MyselfPeer.fromJson(map);
    };
    connectAction.responseStreamController.stream
        .listen((ChainMessage chainMessage) {
      _connectResponse(chainMessage);
    });
  }

  @override
  Future<List<MyselfPeer>> findAll() async {
    List<MyselfPeer> myselfPeers = await find();
    if (myselfPeers.isNotEmpty) {
      for (var myselfPeer in myselfPeers) {
        String? data = myselfPeer.avatar;
        if (data != null) {
          var avatarImage = ImageUtil.buildImageWidget(
              image: data,
              height: AppIconSize.lgSize,
              width: AppIconSize.lgSize,
              fit: BoxFit.contain);
          myselfPeer.avatarImage = avatarImage;
        }
      }
    }

    return myselfPeers;
  }

  Future<void> _connectResponse(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = chainMessage.payload;
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          await peerClientService.store(peerClient,
              mobile: false, email: false);
        }
      }
    }
  }

  Future<MyselfPeer?> findOneByLogin(String credential) async {
    var where = '(peerId=? or mobile=? or loginName=? or email=?) and status=?';
    var whereArgs = [
      credential,
      credential,
      credential,
      credential,
      EntityStatus.effective.name
    ];
    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  Future<MyselfPeer?> findOneByLoginName(String loginName) async {
    var where = 'loginName = ?';
    var whereArgs = [loginName];

    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  ///只保存新的自己的信息
  Future<MyselfPeer?> storeByPeerEntity(PeerEntity peerEntity) async {
    String peerId = peerEntity.peerId;
    MyselfPeer? myselfPeer = await findOneByPeerId(peerId);
    if (myselfPeer != null) {
      myselfPeer.email = peerEntity.email;
      myselfPeer.mobile = peerEntity.mobile;
      myselfPeer.name = peerEntity.name;
      myselfPeer.clientId = peerEntity.clientId;
      myselfPeer.avatar = peerEntity.avatar;
      myselfPeer.status = peerEntity.status;
      myselfPeer.address = peerEntity.address;
      myselfPeer.startDate = peerEntity.startDate;
      myselfPeer.endDate = peerEntity.endDate;
      myselfPeer.activeStatus = peerEntity.activeStatus;
      myselfPeer.trustLevel = peerEntity.trustLevel;
      await update(myselfPeer);
      if (peerId == myself.peerId) {
        PeerProfile? peerProfile =
            await peerProfileService.findCachedOneByPeerId(peerId);
        if (peerProfile != null) {
          myselfPeer.peerProfile = peerProfile;
          myself.myselfPeer = myselfPeer;
        }
      }
    }

    return myselfPeer;
  }

  /// 注册新的p2p账户
  Future<MyselfPeer> register(String name, String loginName, String password,
      {String? code, String? mobile, String? email}) async {
    if (code != null && mobile != null) {
      var isPhoneNumberValid = false;
      try {
        IsoCode? isoCode = StringUtil.enumFromString(IsoCode.values, code);
        PhoneNumber phoneNumber = PhoneNumberUtil.fromIsoCode(isoCode!, mobile);
        isPhoneNumberValid = PhoneNumberUtil.validate(phoneNumber);

        if (!isPhoneNumberValid) {
          throw 'Invalid mobile number';
        }
        mobile = PhoneNumberUtil.format(phoneNumber, isoCode: isoCode);
      } catch (e) {
        logger.e(e);
      }
    }
    var peer = await findOneByName(name);
    if (peer != null) {
      throw 'Same name account exist';
    }
    peer = await findOneByLoginName(loginName);
    if (peer != null) {
      throw 'Same loginName account exist';
    }
    var deviceData = platformParams.deviceData;
    var clientDevice = JsonUtil.toJsonString(deviceData);
    var hash = await cryptoGraphy.hash(clientDevice.codeUnits);
    var clientId = CryptoUtil.encodeBase58(hash);
    var myselfPeer = MyselfPeer('', name, clientId, loginName);
    myselfPeer.status = EntityStatus.effective.name;
    myselfPeer.mobile = mobile;
    myselfPeer.email = email;
    myselfPeer.address = await NetworkInfoUtil.getWifiIp();
    await myselfService.createMyself(myselfPeer, password);

    var currentDate = DateUtil.currentDate();
    myselfPeer.createDate = currentDate;
    myselfPeer.updateDate = currentDate;
    myselfPeer.startDate = currentDate;
    myselfPeer.endDate = '9999-12-31T11:59:59.999Z';
    myselfPeer.statusDate = currentDate;
    await store(myselfPeer);

    // 初始化profile
    String? peerId = myselfPeer.peerId;
    var profile = await peerProfileService.findOneByPeerId(peerId);
    if (profile != null) {
      peerProfileService.delete(entity: profile);
    }
    var peerProfile = PeerProfile(peerId, clientId: myselfPeer.clientId);
    peerProfile.peerId = peerId;
    peerProfile.ownerPeerId = peerId;
    peerProfile.status = EntityStatus.effective.name;
    peerProfile.creditScore = 300;
    peerProfile.mobileVerified = false;
    peerProfile.visibilitySetting = 'YYYYYY';
    peerProfile.clientDevice = clientDevice;
    peerProfile.vpnSwitch = false;
    peerProfile.stockSwitch = false;
    peerProfile.emalSwitch = false;
    peerProfile.autoLogin = false;
    peerProfile.developerSwitch = false;
    peerProfile.logLevel = 'none';
    peerProfile.lastSyncTime = currentDate;
    await peerProfileService.upsert(peerProfile);
    myselfPeer.peerProfile = peerProfile;

    return myselfPeer;
  }

  ///获取最后一次登录的用户名
  Future<String?> lastCredentialName() async {
    String? lastLoginStr =
        await localSharedPreferences.get(lastLoginName, userKey: false);
    if (StringUtil.isNotEmpty(lastLoginStr)) {
      Map<String, dynamic> skipLogin = JsonUtil.toJson(lastLoginStr);
      String? credential = skipLogin[credentialName];
      return credential;
    }
    return null;
  }

  ///获取自动登录的用户名和密码
  Future<Map<String, dynamic>?> autoCredential() async {
    String? autoLoginStr = await localSecurityStorage.get(autoLoginName);
    if (StringUtil.isNotEmpty(autoLoginStr)) {
      Map<String, dynamic> autoLogin = JsonUtil.toJson(autoLoginStr);
      return autoLogin;
    }

    return null;
  }

  ///获取最后一次登录的用户名和密码，如果都存在，快捷登录
  Future<void> removeAutoCredential() async {
    await localSecurityStorage.remove(autoLoginName);
  }

  Future<void> saveAutoCredential(String credential, String password) async {
    //记录最后成功登录的用户名和密码
    String skipLogin = JsonUtil.toJsonString(
        {credentialName: credential, passwordName: password});
    await localSecurityStorage.save(autoLoginName, skipLogin);
  }

  Future<void> saveLastCredentialName(String credential) async {
    //最后一次成功登录的用户名
    String lastLogin = JsonUtil.toJsonString({credentialName: credential});
    await localSharedPreferences.save(lastLoginName, lastLogin, userKey: false);
  }

  ///获取最后一次登录的用户名和密码，如果都存在，快捷登录
  Future<bool> autoLogin() async {
    Map<String, dynamic>? autoLogin = await autoCredential();
    if (autoLogin != null) {
      String? credential = autoLogin[credentialName];
      String? password = autoLogin[passwordName];
      if (StringUtil.isNotEmpty(credential) &&
          StringUtil.isNotEmpty(password)) {
        bool loginStatus = await login(credential!, password!);
        return loginStatus;
      }
    }

    return false;
  }

  /// 验证本地账户
  Future<bool> auth(String credential, String password) async {
    ///本地查找账户
    MyselfPeer? myselfPeer = await myselfPeerService.findOneByLogin(credential);
    if (myselfPeer != null) {
      /// 1.验证账户与密码匹配
      try {
        var loginStatus = await myselfService.auth(myselfPeer, password);

        return loginStatus;
      } catch (err) {
        logger.e('login err:$err');
        return false;
      }
    }
    return false;
  }

  /// 登录，验证本地账户，连接p2p服务节点，注册成功
  Future<bool> login(String credential, String password) async {
    ///本地查找账户
    MyselfPeer? myselfPeer = await myselfPeerService.findOneByLogin(credential);
    if (myselfPeer != null) {
      /// 1.验证账户与密码匹配
      try {
        var loginStatus = await myselfService.login(myselfPeer, password);
        if (!loginStatus) {
          return false;
        } else {
          await saveLastCredentialName(credential);
        }
      } catch (err) {
        logger.e('login err:$err');
        return false;
      }

      ///2.启动android后台服务
      if (platformParams.android) {
        try {
          androidBackgroundService.start();
        } catch (e) {
          logger.e('androidForegroundService start failure:$e');
        }
      }

      // if (platformParams.mobile) {
      //   try {
      //     bool success = await backgroundService.start();
      //     if (success) {
      //       logger.i('backgroundService start');
      //     } else {
      //       logger.e('backgroundService start failure');
      //     }
      //   } catch (e) {
      //     logger.e('backgroundService start failure:$e');
      //   }
      // }

      ///3.连接篇p2p的节点，把自己的信息注册上去
      await connect();
      await postLogin();
      return true;
    } else {
      logger.e('$credential is not exist');
    }

    return false;
  }

  Future<void> connect() async {
    if (myself.id != null) {
      MyselfPeer myselfPeer = myself.myselfPeer;
      var json = JsonUtil.toJson(myselfPeer);
      var peerClient = PeerClient.fromJson(json);
      peerClient.activeStatus = ActiveStatus.Up.name;
      peerClient.clientId = myselfPeer.clientId;
      bool success = await connectAction.connect(peerClient);
      if (success) {
        logger.i('login connect successfully,activeStatus up');
        //设置firebase token
        firebaseMessagingService.getToken().then((String? fcmToken) {
          logger.w('fcmToken:$fcmToken');
          peerClient.deviceToken = fcmToken;
          peerClient.deviceDesc = platformParams.operatingSystem;
          if (platformParams.ios || platformParams.macos) {
            firebaseMessagingService.getAPNSToken().then((String? apnsToken) {
              logger.w('apnsToken:$apnsToken');
            });
          }
        });
      }
    }
  }

  ///登录成功后执行
  Future<void> postLogin() async {
    var peerId = peerConnectionPool.peerId;
    logger.i('peerConnectionPool init: $peerId');
    signalSessionPool.init();
    shareService.init();
  }

  Future<bool> logout() async {
    bool result = false;

    ///本地查找账户
    var peerId = myself.peerId;
    if (peerId != null) {
      try {
        MyselfPeer? myselfPeer =
            await myselfPeerService.findOneByPeerId(peerId);

        ///2.连接篇p2p的节点，把自己的信息注册上去
        if (myselfPeer != null) {
          var json = JsonUtil.toJson(myselfPeer);
          var peerClient = PeerClient.fromJson(json);
          peerClient.activeStatus = ActiveStatus.Down.name;
          peerClient.clientId = myselfPeer.clientId;
          await connectAction.connect(peerClient);
          logger.w('logout connect successfully,activeStatus down');

          result = true;
        } else {
          logger.e('myselfPeer:$peerId is not exist');
        }
      } catch (e) {
        logger.e('logout err:$e');
      }
    }
    myselfService.logout();
    await postLogout();

    return result;
  }

  ///登出成功后执行
  Future<void> postLogout() async {
    await removeAutoCredential();
    peerConnectionPool.clear();
    signalSessionPool.clear();
  }

  ///保存MyselfPeer，同时保存对应的PeerClient和Linkman
  Future<void> store(MyselfPeer myself) async {
    MyselfPeer? myselfPeer =
        await findOne(where: 'peerId=?', whereArgs: [myself.peerId]);
    if (myselfPeer == null) {
      await insert(myself);
    } else {
      myself.id = myselfPeer.id;
      await update(myself);
    }
    var json = JsonUtil.toJson(myself);
    PeerClient peerClient = PeerClient.fromJson(json);
    await peerClientService.storeByPeerEntity(peerClient);
    await linkmanService.storeByPeerEntity(peerClient);
  }

  @override
  Future<String> updateAvatar(String peerId, List<int> avatar) async {
    String data = await super.updateAvatar(peerId, avatar);
    final myselfPeer = myself.myselfPeer;
    myselfPeer.avatar = data;
    var avatarImage = ImageUtil.buildImageWidget(
        image: data,
        height: AppIconSize.lgSize,
        width: AppIconSize.lgSize,
        fit: BoxFit.contain);
    myselfPeer.avatarImage = avatarImage;
    var avatarIcon = ImageIcon(
      AssetImage(
        data,
      ),
      size: AppIconSize.lgSize,
    );
    myselfPeer.avatarIcon = avatarIcon;
    await peerClientService.updateAvatar(peerId, avatar);
    await linkmanService.updateAvatar(peerId, avatar);

    return data;
  }

  Future<String?> backup(String peerId) async {
    MyselfPeer? myselfPeer = await findOneByPeerId(peerId);
    if (myselfPeer != null) {
      Map<String, dynamic> myselfPeerMap = JsonUtil.toJson(myselfPeer);
      String name = myselfPeer.name;
      PeerProfile? peerProfile =
          await peerProfileService.findOneByPeerId(peerId);
      if (peerProfile != null) {
        Map<String, dynamic> peerProfileMap = JsonUtil.toJson(peerProfile);
        myselfPeerMap['peerProfile'] = peerProfileMap;
      }

      String backup = JsonUtil.toJsonString(myselfPeerMap);
      var current = DateTime.now();
      var filename =
          '${name}_$peerId-${current.year}-${current.month}-${current.day}.json';
      filename = p.join(platformParams.path, name, filename);
      File file = File(filename);
      file.writeAsStringSync(backup);

      return filename;
    }

    return null;
  }

  Future<String> restore(String backup) async {
    Map<String, dynamic> myselfPeerMap = JsonUtil.toJson(backup);
    MyselfPeer myselfPeer = MyselfPeer.fromJson(myselfPeerMap);
    store(myselfPeer);
    Map<String, dynamic>? peerProfileMap = myselfPeerMap['peerProfile'];
    if (peerProfileMap != null) {
      PeerProfile peerProfile = PeerProfile.fromJson(peerProfileMap);
      await peerProfileService.store(peerProfile);
    }

    return myselfPeer.peerId;
  }
}

final myselfPeerService = MyselfPeerService(
    tableName: "blc_myselfpeer",
    indexFields: [
      'endDate',
      'peerId',
      'name',
      'mobile',
      'email',
      'status',
      'updateDate'
    ],
    fields: ServiceLocator.buildFields(MyselfPeer('', '', '', ''), []));
