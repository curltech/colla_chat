import 'package:colla_chat/app.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/service/dht/myself.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';

import '../../entity/base.dart';
import '../../entity/dht/base.dart';
import '../../entity/dht/myself.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../entity/dht/peerprofile.dart';
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
    Map<dynamic, dynamic>? peer = await findOneEffectiveByMobile(credential);
    peer ??= await findOneEffectiveByPeerId(credential);
    peer ??= await findOneEffectiveByName(credential);
    peer ??= await findOneEffectiveByEmail(credential);

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
    myselfPeer.status = EntityStatus.Effective.toString();
    myselfPeer.mobile = mobile;
    myselfPeer.email = email;
    myselfPeer.name = name;
    myselfPeer.loginName = loginName;
    myselfPeer.address = await NetworkInfoUtil.getWifiIp();
    await myselfService.createMyself(myselfPeer, password);

    var currentDate = DateTime.now().toIso8601String();
    myselfPeer.createDate = currentDate;
    myselfPeer.updateDate = currentDate;
    myselfPeer.lastUpdateTime = currentDate;
    myselfPeer.startDate = currentDate;
    myselfPeer.endDate = '9999-12-31T11:59:59.999Z';
    myselfPeer.statusDate = currentDate;
    myselfPeer.version = 0;
    myselfPeer.creditScore = 300;
    myselfPeer.mobileVerified = 'N';
    myselfPeer.visibilitySetting = 'YYYYYY';
    await upsert(myselfPeer);
    myself.myselfPeer = myselfPeer;

    // 初始化profile
    String peerId = myselfPeer.peerId;
    var profile = await peerProfileService.findOneEffectiveByPeerId(peerId);
    if (profile != null) {
      await peerProfileService.delete(profile);
    }
    var peerProfile = PeerProfile();
    peerProfile.peerId = peerId;
    peerProfile.status = EntityStatus.Effective.toString();
    peerProfile.clientId = myselfPeer.id.toString();
    var platformParams = await PlatformParams.instance;
    peerProfile.clientType = platformParams.clientType;
    peerProfile.clientDevice = platformParams.clientDevice;
    var appParams = await AppParams.instance;
    peerProfile.language = appParams.language;
    peerProfile.lightDarkMode = 'auto';
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

      return true;
    }

    return false;
  }
}

final myselfPeerService = MyselfPeerService.instance;
