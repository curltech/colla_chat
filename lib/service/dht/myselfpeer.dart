import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/dht/myself.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/service/servicelocator.dart';

import '../../crypto/util.dart';
import '../../entity/base.dart';
import '../../entity/dht/base.dart';
import '../../entity/dht/myself.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../entity/dht/peerclient.dart';
import '../../entity/dht/peerprofile.dart';
import '../../entity/p2p/message.dart';
import '../../p2p/chain/action/connect.dart';
import '../../p2p/chain/baseaction.dart';
import '../../platform.dart';
import '../../tool/util.dart';
import 'base.dart';

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
    var where = '(peerId=? or mobile=? or name=? or email=?) and status=?';
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
    var deviceData = PlatformParams.instance.deviceData;
    var clientDevice = JsonUtil.toJsonString(deviceData);
    var hash = await cryptoGraphy.hash(clientDevice.codeUnits);
    var clientId = CryptoUtil.encodeBase58(hash);
    var myselfPeer = MyselfPeer('', '', clientId);
    myselfPeer.status = EntityStatus.effective.name;
    myselfPeer.mobile = mobile;
    myselfPeer.email = email;
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
    var platformParams = PlatformParams.instance;
    peerProfile.clientDevice = clientDevice;
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
    var myselfPeer = await myselfPeerService.findOneByLogin(credential);
    if (myselfPeer != null) {
      /// 1.验证账户与密码匹配
      var loginStatus = await myselfService.setMyself(myselfPeer, password);

      if (loginStatus) {
        ///2.连接篇p2p的节点，把自己的信息注册上去
        var json = JsonUtil.toJson(myselfPeer);
        var peerClient = PeerClient.fromJson(json);
        peerClient.activeStatus = ActiveStatus.Up.name;
        peerClient.clientId = myselfPeer.clientId;
        peerClient.expireDate = DateTime.now().millisecondsSinceEpoch;
        peerClient.name = String.fromCharCodes(
            await cryptoGraphy.hash(peerClient.name.codeUnits));
        peerClient.mobile = String.fromCharCodes(
            await cryptoGraphy.hash(peerClient.mobile.codeUnits));
        peerClient.email = String.fromCharCodes(
            await cryptoGraphy.hash(peerClient.email.codeUnits));
        connectAction.connect(peerClient).then((response) {
          logger.i(response);
        });
      }
      return loginStatus;
    } else {
      logger.e('$credential is not exist');
    }

    return false;
  }

  void logout() {
    ///本地查找账户
    var peerId = myself.peerId;
    if (peerId != null) {
      try {
        myselfPeerService
            .findOneByPeerId(peerId)
            .then((MyselfPeer? myselfPeer) {
          ///2.连接篇p2p的节点，把自己的信息注册上去
          if (myselfPeer != null) {
            var json = JsonUtil.toJson(myselfPeer);
            var peerClient = PeerClient.fromJson(json);
            peerClient.activeStatus = ActiveStatus.Down.name;
            peerClient.clientId = myselfPeer.clientId;
            peerClient.expireDate = DateTime.now().millisecondsSinceEpoch;
            peerClient.kind = null;
            peerClient.name = '';
            connectAction
                .connect(peerClient)
                .then((ChainMessage? chainMessage) {
              myselfService.clear();
            });
          }
        });
      } catch (e) {
        myselfService.clear();
      }
    }
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
    fields: ServiceLocator.buildFields(MyselfPeer('', '', ''), []));
