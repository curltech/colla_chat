import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/dht/myself.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/network_connectivity.dart';
import 'package:colla_chat/tool/phone_number_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';

import '../../crypto/signalprotocol.dart';
import '../../crypto/util.dart';
import '../../entity/base.dart';
import '../../entity/dht/base.dart';
import '../../entity/dht/myself.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../entity/dht/peerclient.dart';
import '../../entity/dht/peerprofile.dart';
import '../../entity/p2p/chain_message.dart';
import '../../p2p/chain/action/connect.dart';
import '../../p2p/chain/baseaction.dart';
import '../../platform.dart';
import '../../plugin/security_storage.dart';
import 'base.dart';

const String skipLoginName = 'skipLogin';
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
    connectAction.registerResponser(_connectResponse);
  }

  Future<void> _connectResponse(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = chainMessage.payload;
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          await peerClientService.store(peerClient);
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

  /// 注册新的p2p账户
  Future<bool> register(String name, String loginName, String password,
      {String? code, String? mobile, String? email}) async {
    if (code != null && mobile != null) {
      var isPhoneNumberValid = false;
      try {
        isPhoneNumberValid = await PhoneNumberUtil.validate(mobile, code);
      } catch (e) {
        logger.e(e);
      }
      if (!isPhoneNumberValid) {
        throw 'InvalidMobileNumber';
      }
      mobile = await PhoneNumberUtil.format(mobile, code);
    }
    var peer = await findOneByName(name);
    if (peer != null) {
      throw 'SameNameAccountExists';
    }
    peer = await findOneByName(loginName);
    if (peer != null) {
      throw 'SameLoginNameAccountExists';
    }
    var deviceData = platformParams.deviceData;
    var clientDevice = JsonUtil.toJsonString(deviceData);
    var hash = await cryptoGraphy.hash(clientDevice.codeUnits);
    var clientId = CryptoUtil.encodeBase58(hash);
    var myselfPeer = MyselfPeer('', clientId, name, loginName);
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
    await upsert(myselfPeer);
    myself.myselfPeer = myselfPeer;

    // 初始化profile
    String? peerId = myselfPeer.peerId;
    var profile = await peerProfileService.findOneByPeerId(peerId!);
    if (profile != null) {
      await peerProfileService.delete(profile);
    }
    var peerProfile = PeerProfile(peerId, myselfPeer.clientId);
    peerProfile.peerId = peerId;
    peerProfile.status = EntityStatus.effective.name;
    peerProfile.creditScore = 300;
    peerProfile.mobileVerified = 'N';
    peerProfile.visibilitySetting = 'YYYYYY';
    peerProfile.clientDevice = clientDevice;
    peerProfile.locale = appDataProvider.locale;
    peerProfile.brightness = appDataProvider.brightness;
    peerProfile.primaryColor = '#19B7C7';
    peerProfile.secondaryColor = '#117EED';
    peerProfile.udpSwitch = false;
    peerProfile.downloadSwitch = false;
    peerProfile.localDataCryptoSwitch = false;
    peerProfile.autoLoginSwitch = true;
    peerProfile.developerOption = false;
    peerProfile.logLevel = 'none';
    peerProfile.lastSyncTime = currentDate;
    await peerProfileService.upsert(peerProfile);
    myself.peerProfile = peerProfile;

    return true;
  }

  ///获取最后一次登录的用户名
  Future<String?> lastCredentialName() async {
    String? lastLoginStr = await localSecurityStorage.get(lastLoginName);
    if (StringUtil.isNotEmpty(lastLoginStr)) {
      Map<String, dynamic> skipLogin = JsonUtil.toJson(lastLoginStr);
      String? credential = skipLogin[credentialName];
      return credential;
    }
    return null;
  }

  ///获取最后一次登录的用户名和密码，如果都存在，快捷登录
  Future<Map<String, dynamic>?> credential() async {
    String? skipLoginStr = await localSecurityStorage.get(skipLoginName);
    if (StringUtil.isNotEmpty(skipLoginStr)) {
      Map<String, dynamic> skipLogin = JsonUtil.toJson(skipLoginStr);
      return skipLogin;
    }

    return null;
  }

  ///获取最后一次登录的用户名和密码，如果都存在，快捷登录
  Future<void> removeCredential() async {
    await localSecurityStorage.remove(skipLoginName);
    await localSecurityStorage.remove(lastLoginName);
  }

  Future<void> saveCredential(String credential, String password) async {
    //最后一次成功登录的用户名
    String lastLogin = JsonUtil.toJsonString({credentialName: credential});
    await localSecurityStorage.save(lastLoginName, lastLogin);
    //记录最后成功登录的用户名和密码
    String skipLogin = JsonUtil.toJsonString(
        {credentialName: credential, passwordName: password});
    await localSecurityStorage.save(skipLoginName, skipLogin);
  }

  /// 登录，验证本地账户，连接p2p服务节点，注册成功
  Future<bool> login(String credential, String password) async {
    ///本地查找账户
    var myselfPeer = await myselfPeerService.findOneByLogin(credential);
    if (myselfPeer != null) {
      /// 1.验证账户与密码匹配
      try {
        var loginStatus = await myselfService.login(myselfPeer, password);
        if (!loginStatus) {
          return false;
        }
      } catch (err) {
        logger.e('login err:$err');
        return false;
      }

      ///2.连接篇p2p的节点，把自己的信息注册上去
      var json = JsonUtil.toJson(myselfPeer);
      var peerClient = PeerClient.fromJson(json);
      peerClient.activeStatus = ActiveStatus.Up.name;
      peerClient.clientId = myselfPeer.clientId;
      var response = await connectAction.connect(peerClient);
      if (response != null) {
        logger.i('connect successfully');
      }
      await postLogin();
      return true;
    } else {
      logger.e('$credential is not exist');
    }

    return false;
  }

  ///登录成功后执行
  Future<void> postLogin() async {
    var peerId = peerConnectionPool.peerId;
    logger.i('peerConnectionPool init: $peerId');
    signalSessionPool.init();
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
          ChainMessage? chainMessage = await connectAction.connect(peerClient);

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
    await removeCredential();
    peerConnectionPool.clear();
    signalSessionPool.clear();
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
