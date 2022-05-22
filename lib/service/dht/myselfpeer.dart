

import 'package:colla_chat/app.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';

import '../../entity/base.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../entity/dht/peerprofile.dart';
import '../../platform.dart';
import '../../service/base.dart';
import '../../tool/util.dart';
import 'base.dart';

class MyselfPeerService extends PeerEntityService {
  static final MyselfPeerService _instance = MyselfPeerService();
  static bool initStatus = false;

  static MyselfPeerService get instance{
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
  
  /// 注册新的p2p账户
  Future<Myself> register(registerData) async {
    var mobile = null;
    var code_ = registerData.code;
    var mobile_ = registerData.mobile;
    if (code_ && mobile_) {
      var isPhoneNumberValid = false;
      try {
        isPhoneNumberValid = await PhoneNumberUtil.validate(mobile_, code_);
      } catch (e) {
        print(e);
      }
      if (!isPhoneNumberValid) {
        throw 'InvalidMobileNumber';
      }
      mobile = await PhoneNumberUtil.format(mobile_, code_);
    }
    var password = registerData.password;
    var name = registerData.name;
    if (password != registerData.confirmPassword) {
      throw 'ErrorPassword';
    }
    var account = await findOneEffectiveByName(name);
    if (account!=null) {
      throw 'SameNameAccountExists';
    }
    var myselfPeer = MyselfPeer();
    myselfPeer.status = EntityStatus.Effective.toString();
    myselfPeer.mobile = mobile;
    myselfPeer.name = name;
    myselfPeer.address = '127.0.0.1:8088';
    //await p2pPeer.initMyself(password, myselfPeer);
    myselfPeer = myself.myselfPeer;
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
    String peerId=myselfPeer.peerId;
    var profile = await PeerProfileService.instance.findOneEffectiveByPeerId(peerId);
    if (profile!=null) {
      await PeerProfileService.instance.delete(profile);
    }
    var peerProfile = PeerProfile();
    peerProfile.peerId = peerId;
    peerProfile.status = EntityStatus.Effective.toString();
    peerProfile.clientId = myselfPeer.id.toString();
    var platformParams=await PlatformParams.instance;
    peerProfile.clientType = platformParams.clientType;
    peerProfile.clientDevice = platformParams.clientDevice;
    var appParams=await AppParams.instance;
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
    await PeerProfileService.instance.upsert(peerProfile);
    myself.peerProfile = peerProfile;

    return myself;
  }

  /// 登录
  Future<Myself> login(loginData) async  {
    var mobile = null;
    var code_ = loginData.code;
    var mobile_ = loginData.credential;
    if (code_ && mobile_) {
      var isPhoneNumberValid = false;
      try {
        isPhoneNumberValid = MobileNumberUtil.isPhoneNumberValid(mobile_, MobileNumberUtil.getRegionCodeForCountryCode(code_));
      } catch (e) {
        console.log(e);
      }
      if (!isPhoneNumberValid) {
        throw new Error('InvalidMobileNumber');
      }
      mobile = MobileNumberUtil.formatE164(mobile_, MobileNumberUtil.getRegionCodeForCountryCode(code_));
    }
    var name = loginData.name;
    var password = loginData.password;
    await p2pPeer.getMyself(password, undefined, mobile, name);
    // 标志登录成功
    if (myself.myselfPeer) {
      cookie.setCookie('token', myself.myselfPeer.peerId);

      return myself;
    }

    return null;
  }

  /// 修改密码
    Future<Myself>  changePassword(oldPassword: string, newPassword: string) async{
    // 使用新密码重新加密所有密钥（包括expired记录）
    var condition = {};
    condition['peerId'] = myself.myselfPeer.peerId;
    condition['endDate'] = {$gt: null};
    var myselfPeers = await this.find(condition, [{endDate: 'desc'}], null, 0, 0);
    if (myselfPeers && myselfPeers.length > 0) {
      var currentDate = new Date();
      for (var myselfPeer of myselfPeers) {
        var privateKey = null;
        var priv = null;
        try {
          privateKey = await openpgp.import(myselfPeer.privateKey, {password: oldPassword});
          if (privateKey) {
            var isEncrypted = privateKey.isEncrypted;
            console.log('isEncrypted:' + isEncrypted);
            if (isEncrypted) {
              await privateKey.decrypt(oldPassword);
            }
          }
          priv = await libp2pcrypto.keys.import(myselfPeer.peerPrivateKey, oldPassword);
        } catch (e) {
          console.error(e);
          throw new Error('WrongPassword');
        }
        myselfPeer.privateKey = await openpgp.export(privateKey, newPassword);
        myselfPeer.peerPrivateKey = await priv.export(newPassword, 'libp2p-key');
        myselfPeer.signalPrivateKey = await signalProtocol.export(newPassword);
        myselfPeer.updateDate = currentDate;
      }
      myselfPeers = await this.update(myselfPeers);
      for (var myselfPeer of myselfPeers) {
        if (myselfPeer._id === myself.myselfPeer._id) {
          myself.myselfPeer = myselfPeer;
          myself.myselfPeerClient.privateKey = myselfPeer.privateKey;
          myself.myselfPeerClient.peerPrivateKey = myselfPeer.peerPrivateKey;
          myself.myselfPeerClient.signalPrivateKey = myselfPeer.signalPrivateKey;
          break;
        }
      }
      myself.password = newPassword;
    }

    return myself;
  }

  /// 更新密钥
Future<Myself>  resetKey() async {
    var currentDate = new Date();
    var oldMyselfPeer = myself.myselfPeer;
    console.log(oldMyselfPeer);
    var newMyselfPeer = CollaUtil.clone(oldMyselfPeer);
    console.log(newMyselfPeer);
    oldMyselfPeer.status = EntityStatus[EntityStatus.Discarded];
    oldMyselfPeer.statusDate = currentDate;
    oldMyselfPeer.endDate = currentDate;
    oldMyselfPeer.updateDate = currentDate;
    await this.update(oldMyselfPeer);

    /**
     加密对应的密钥对openpgp
     */
    var password = myself.password;
    var userIds = [{name: newMyselfPeer.name, mobile: newMyselfPeer.mobile, peerId: newMyselfPeer.peerId}];
    var keyPair = await openpgp.generateKey({
      userIds: userIds,
      namedCurve: 'ed25519',
      passphrase: password
    });
    var privateKey = keyPair.privateKey;
    newMyselfPeer.privateKey = await openpgp.export(privateKey, password);
    //var privateKey = await openpgp.import(newMyselfPeer.privateKey, { password: password })
    newMyselfPeer.publicKey = await openpgp.export(keyPair.publicKey, '');

    newMyselfPeer.createDate = currentDate;
    newMyselfPeer.updateDate = currentDate;
    newMyselfPeer.lastUpdateTime = currentDate;
    newMyselfPeer.startDate = currentDate;
    newMyselfPeer.endDate = new Date("9999-12-31T11:59:59.999Z");
    newMyselfPeer.status = EntityStatus[EntityStatus.Effective];
    newMyselfPeer.statusDate = currentDate;
    newMyselfPeer.version = newMyselfPeer.version + 1;
    newMyselfPeer._id = undefined;
    newMyselfPeer._rev = undefined;
    newMyselfPeer = await this.insert(newMyselfPeer);

    myself.myselfPeer = newMyselfPeer;
    this.setMyselfPeerClient();

    if (privateKey) {
      var isDecrypted = privateKey.isDecrypted();
      console.log('isDecrypted:' + isDecrypted);
      if (!isDecrypted) {
        await privateKey.decrypt(password);
      }
    }
    //myself.privateKey = keyPair.privateKey
    myself.privateKey = privateKey;
    myself.publicKey = keyPair.publicKey;

    return myself;
  }

Future<int>  importID(json: string) async {
    var ret: number = 0;
    console.log('importID json:' + json);
    var peers = JSON.parse(json);
    if (!peers || !peers[0] || !peers[0].peerId || !peers[0].name) {
      throw new Error('InvalidID');
    } else {
      var condition = {};
      condition['peerId'] = peers[0].peerId;
      var result = await this.find(condition, null, null, 0, 0);
      if (result && result.length > 0) {
        throw new Error('AccountExists');
      }
      var currentDate = new Date();
      var mobile = peers[0].mobile;
      var myselfPeer = new MyselfPeer();
      myselfPeer.peerId = peers[0].peerId;
      myselfPeer.mobile = mobile;
      condition = {status: EntityStatus[EntityStatus.Effective]};
      condition['name'] = peers[0].name;
      result = await this.find(condition, null, null, 0, 0);
      if (result && result.length > 0) {
        myselfPeer.name = peers[0].name + '(' + result.length + ')';
        ret = result.length;
      } else {
        myselfPeer.name = peers[0].name;
      }
      myselfPeer.peerPrivateKey = peers[0].peerPrivateKey;
      myselfPeer.peerPublicKey = peers[0].peerPublicKey;
      myselfPeer.privateKey = peers[0].privateKey;
      myselfPeer.publicKey = peers[0].publicKey;
      myselfPeer.address = '127.0.0.1:8088';
      myselfPeer.lastUpdateTime = peers[0].lastUpdateTime;
      myselfPeer.securityContext = '{\"protocol\":\"OpenPGP\",\"keyPairType\":\"Ed25519\"}';
      myselfPeer.createDate = currentDate;
      myselfPeer.updateDate = currentDate;
      myselfPeer.startDate = currentDate;
      myselfPeer.endDate = new Date('9999-12-31T11:59:59.999Z');
      myselfPeer.status = EntityStatus[EntityStatus.Effective];
      myselfPeer.statusDate = currentDate;
      myselfPeer.version = 0;
      myselfPeer.creditScore = 300;
      myselfPeer.mobileVerified = peers[0].mobileVerified;
      myselfPeer.visibilitySetting = peers[0].visibilitySetting;
      myselfPeer = await this.upsert(myselfPeer);
      if (myselfPeer) {
        // 初始化profile
        var peerProfile = new PeerProfile();
        peerProfile.clientId = myselfPeer._id + '';
        peerProfile.peerId = myselfPeer.peerId;
        peerProfile.clientType = config.platformParams.clientType;
        peerProfile.clientDevice = config.platformParams.clientDevice;
        peerProfile.language = peers[0].language;
        peerProfile.lightDarkMode = peers[0].lightDarkMode;
        peerProfile.primaryColor = peers[0].primaryColor;
        peerProfile.secondaryColor = peers[0].secondaryColor;
        peerProfile.udpSwitch = peers[0].udpSwitch;
        peerProfile.downloadSwitch = peers[0].downloadSwitch;
        peerProfile.localDataCryptoSwitch = peers[0].localDataCryptoSwitch;
        peerProfile.autoLoginSwitch = peers[0].autoLoginSwitch;
        peerProfile.developerOption = peers[0].developerOption;
        peerProfile.logLevel = peers[0].logLevel;
        peerProfile.lastSyncTime = new Date('1970-01-01T00:00:00.000Z');
        peerProfile.status = EntityStatus[EntityStatus.Effective];
        peerProfile.statusDate = currentDate;
        peerProfile = await peerProfileService.upsert(peerProfile);

        myself.myselfPeer = myselfPeer;
        myself.peerProfile = peerProfile;
      }
    }

    return ret;
  }

  String exportID() {
    var json = '';
    if (myself.myselfPeerClient) {
      var peers = [CollaUtil.clone(myself.myselfPeerClient)];
      delete peers[0]._id;
      delete peers[0]._rev;
      delete peers[0].avatar;
      delete peers[0].address;
      delete peers[0].securityContext;
      delete peers[0].createDate;
      delete peers[0].updateDate;
      delete peers[0].startDate;
      delete peers[0].endDate;
      delete peers[0].status;
      delete peers[0].statusReason;
      delete peers[0].statusDate;
      delete peers[0].version;
      delete peers[0].creditScore;
      delete peers[0].activeStatus;
      delete peers[0].clientId;
      delete peers[0].clientType;
      delete peers[0].clientDevice;
      delete peers[0].lastSyncTime;
      delete peers[0].signalPublicKey;
      delete peers[0].signalPrivateKey;
      json = JSON.stringify(peers);
    }

    console.log('exportID json:' + json);
    return json;
  }

  async destroyID() {
    var condition = {};
    condition['peerId'] = myself.myselfPeer.peerId;
    var myselfPeers = await this.find(condition, null, null, 0, 0);
    if (myselfPeers && myselfPeers.length > 0) {
      await this.delete(myselfPeers);
    }

    var peerProfiles = await peerProfileService.find(condition, null, null, 0, 0);
    if (peerProfiles && peerProfiles.length > 0) {
      await peerProfileService.delete(peerProfiles);
    }
  }

  setMyselfPeerClient() {
    if (!myself.myselfPeerClient) {
      myself.myselfPeerClient = {};
    }
    var myselfPeer=myself.myselfPeer;
    if (myselfPeer!=null) {
      var myselfPeerClient=myself.myselfPeerClient;
      if (myselfPeerClient!=null){
myselfPeerClient.peerPrivateKey = myself.myselfPeer.peerPrivateKey;
myself.myselfPeerClient.peerPublicKey = myself.myselfPeer.peerPublicKey;
myself.myselfPeerClient.privateKey = myself.myselfPeer.privateKey;
myself.myselfPeerClient.publicKey = myself.myselfPeer.publicKey;
myself.myselfPeerClient.peerId = myself.myselfPeer.peerId;
myself.myselfPeerClient.mobile = myself.myselfPeer.mobile;
myself.myselfPeerClient.name = myself.myselfPeer.name;
myself.myselfPeerClient.avatar = myself.myselfPeer.avatar,
myself.myselfPeerClient.securityContext = myself.myselfPeer.securityContext;
myself.myselfPeerClient.address = myself.myselfPeer.address;
myself.myselfPeerClient.status = myself.myselfPeer.status;
myself.myselfPeerClient.statusReason = myself.myselfPeer.statusReason;
myself.myselfPeerClient.statusDate = myself.myselfPeer.statusDate;
myself.myselfPeerClient.startDate = myself.myselfPeer.startDate;
myself.myselfPeerClient.endDate = myself.myselfPeer.endDate;
myself.myselfPeerClient.version = myself.myselfPeer.version;
myself.myselfPeerClient.creditScore = myself.myselfPeer.creditScore;
myself.myselfPeerClient.activeStatus = myself.myselfPeer.activeStatus;
myself.myselfPeerClient.mobileVerified = myself.myselfPeer.mobileVerified;
myself.myselfPeerClient.visibilitySetting = myself.myselfPeer.visibilitySetting;
myself.myselfPeerClient.lastUpdateTime = myself.myselfPeer.lastUpdateTime;
myself.myselfPeerClient.signalPublicKey = myself.myselfPeer.signalPublicKey;
myself.myselfPeerClient.signalPrivateKey = myself.myselfPeer.signalPrivateKey;
}
    }
    if (myself.peerProfile) {
      myself.myselfPeerClient.clientId = myself.peerProfile.clientId,
        myself.myselfPeerClient.clientType = myself.peerProfile.clientType,
        myself.myselfPeerClient.clientDevice = myself.peerProfile.clientDevice,
        myself.myselfPeerClient.language = myself.peerProfile.language,
        myself.myselfPeerClient.lightDarkMode = myself.peerProfile.lightDarkMode,
        myself.myselfPeerClient.primaryColor = myself.peerProfile.primaryColor,
        myself.myselfPeerClient.secondaryColor = myself.peerProfile.secondaryColor,
        myself.myselfPeerClient.udpSwitch = myself.peerProfile.udpSwitch,
        myself.myselfPeerClient.downloadSwitch = myself.peerProfile.downloadSwitch,
        myself.myselfPeerClient.localDataCryptoSwitch = myself.peerProfile.localDataCryptoSwitch,
        myself.myselfPeerClient.autoLoginSwitch = myself.peerProfile.autoLoginSwitch,
        myself.myselfPeerClient.developerOption = myself.peerProfile.developerOption,
        myself.myselfPeerClient.logLevel = myself.peerProfile.logLevel,
        myself.myselfPeerClient.lastSyncTime = myself.peerProfile.lastSyncTime;
    }
    return myself.myselfPeerClient;
  }
}
final myselfPeerService = MyselfPeerService.instance;