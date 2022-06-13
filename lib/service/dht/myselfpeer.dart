import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/provider/app_data.dart';
import 'package:colla_chat/service/dht/myself.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';

import '../../crypto/util.dart';
import '../../entity/base.dart';
import '../../entity/dht/base.dart';
import '../../entity/dht/myself.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../entity/dht/peerclient.dart';
import '../../entity/dht/peerprofile.dart';
import '../../p2p/chain/action/connect.dart';
import '../../platform.dart';
import '../../service/base.dart';
import '../../tool/util.dart';
import 'base.dart';

class MyselfPeerService extends PeerEntityService {
  static final MyselfPeerService _instance = MyselfPeerService();
  static bool initStatus = false;

  static MyselfPeerService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<MyselfPeerService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }

  Future<Map?> findOneByLogin(String credential) async {
    var where = 'peerId=? or mobile=? or name=? or email=?';
    var whereArgs = [credential, credential, credential, credential];
    var peers = await find(where, whereArgs: whereArgs);
    if (peers.isNotEmpty) {
      for (var peer in peers) {
        if (peer['status'] == EntityStatus.Effective.name) {
          return peer;
        }
      }
    }
    return null;
  }

  /// 注册新的p2p账户
  Future<bool> register(String name, String loginName, String password,
      {String? code, String? mobile, String? email}) async {
    if (code != null && mobile != null) {
      var isPhoneNumberValid = false;
      try {
        isPhoneNumberValid = await PhoneNumberUtil.validate(mobile, code);
      } catch (e) {
        print(e);
      }
      if (!isPhoneNumberValid) {
        throw 'InvalidMobileNumber';
      }
      mobile = await PhoneNumberUtil.format(mobile, code);
    }
    var peer = await findOneEffectiveByName(name);
    if (peer != null) {
      throw 'SameNameAccountExists';
    }
    var myselfPeer = MyselfPeer();
    myselfPeer.status = EntityStatus.Effective.name;
    myselfPeer.mobile = mobile;
    myselfPeer.email = email;
    var clientDevice = PlatformParams.instance.clientDevice;
    if (clientDevice != null) {
      var hash = await cryptoGraphy.hash(clientDevice.codeUnits);
      myselfPeer.clientId = CryptoUtil.encodeBase58(hash);
    }
    myselfPeer.name = name;
    myselfPeer.loginName = loginName;
    myselfPeer.address = await NetworkInfoUtil.getWifiIp();
    await myselfService.createMyself(myselfPeer, password);

    var currentDate = DateUtil.currentDate();
    myselfPeer.createDate = currentDate;
    myselfPeer.updateDate = currentDate;
    myselfPeer.lastUpdateTime = currentDate;
    myselfPeer.startDate = currentDate;
    myselfPeer.endDate = '9999-12-31T11:59:59.999Z';
    myselfPeer.statusDate = currentDate;
    myselfPeer.version = 0;
    await upsert(myselfPeer);
    myself.myselfPeer = myselfPeer;

    // 初始化profile
    String? peerId = myselfPeer.peerId;
    var profile = await peerProfileService.findOneEffectiveByPeerId(peerId!);
    if (profile != null) {
      await peerProfileService.delete(profile);
    }
    var peerProfile = PeerProfile();
    peerProfile.peerId = peerId;
    peerProfile.status = EntityStatus.Effective.name;
    peerProfile.creditScore = 300;
    peerProfile.mobileVerified = 'N';
    peerProfile.visibilitySetting = 'YYYYYY';
    var platformParams = PlatformParams.instance;
    peerProfile.clientDevice = platformParams.clientDevice;
    var appParams = AppDataProvider.instance;
    peerProfile.locale = appParams.locale;
    peerProfile.brightness = appParams.brightness;
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

  /// 登录，验证本地账户，连接p2p服务节点，注册成功
  Future<bool> login(String credential, String password) async {
    ///本地查找账户
    var peer = await myselfPeerService.findOneByLogin(credential);
    if (peer != null) {
      /// 1.验证账户与密码匹配
      var myselfPeer = MyselfPeer.fromJson(peer);
      await myselfService.setMyself(myselfPeer, password);

      ///2.连接篇p2p的节点，把自己的信息注册上去
      var json = JsonUtil.toMap(myselfPeer);
      var peerClient = PeerClient.fromJson(json);
      peerClient.activeStatus = ActiveStatus.Up.name;
      peerClient.clientId = myselfPeer.clientId;
      peerClient.expireDate = DateTime.now().millisecondsSinceEpoch;
      peerClient.kind = null;
      peerClient.name = null;
      var loginStatus = await connectAction.connect(peerClient);

      return loginStatus;
    } else {
      logger.e('$credential is not exist');
    }

    return false;
  }

  Future<bool> logout() async {
    ///本地查找账户
    var peerId = myself.peerId;
    if (peerId == null) {
      return true;
    }
    var logoutStatus = false;
    var peer = await myselfPeerService.findOneEffectiveByPeerId(peerId);
    if (peer != null) {
      /// 1.验证账户与密码匹配
      var myselfPeer = MyselfPeer.fromJson(peer);

      ///2.连接篇p2p的节点，把自己的信息注册上去
      var json = JsonUtil.toMap(myselfPeer);
      var peerClient = PeerClient.fromJson(json);
      peerClient.activeStatus = ActiveStatus.Down.name;
      peerClient.clientId = myselfPeer.clientId;
      peerClient.expireDate = DateTime.now().millisecondsSinceEpoch;
      peerClient.kind = null;
      peerClient.name = null;
      logoutStatus = await connectAction.connect(peerClient);
      if (!logoutStatus) {
        logger.e('logout fail');
      }
    }
    myselfService.clear();

    return logoutStatus;
  }
}

final myselfPeerService = MyselfPeerService.instance;
