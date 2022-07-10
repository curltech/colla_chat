

import '../../entity/dht/peerclient.dart';
import '../base.dart';
import 'base.dart';

class PeerClientService extends PeerEntityService {
  static final PeerClientService _instance = PeerClientService();
  static bool initStatus = false;

  static PeerClientService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<PeerClientService> init(
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

  var peerClients = <String, PeerClient>{};
  var publicKeys = <String, dynamic>{};

  Future<any> getPublic(String peerId) async {
    var peerClient = await this.getCachedPeerClient(peerId);
    if (peerClient!=null) {
      return this.publicKeys.get(peerId);
    }

    return null;
  }

    PeerClient getPeerClientFromCache(peerId: string)  {
    if (this.peerClients.has(peerId)) {
      return this.peerClients.get(peerId);
    }

    return;
  }

  /// 依次从内存，本地数据库和网络获取PeerClient信息
Future<PeerClient>  getCachedPeerClient(String peerId) async  {
    var best = peerClients[peerId];
    if (best==null) {
      var peerClient = await findOneEffectiveByPeerId(peerId);
      if (peerClient ==null) {
        peerClients = await this.getPeerClient(undefined, peerId, undefined, undefined);
      }
      best = await this.getBestPeerClient(peerClients, peerId);
    }
    return best;
  }

  /// 从网络是获取PeerClient信息，第一个参数可以为空
Future<List<PeerClient>>  getPeerClient(String peerId, String mobileNumber, String name,String connectPeerId) async  {
    var peerClients: PeerClient[] = undefined;
    var pcs: any[] = await findClientAction.findClient(connectPeerId, peerId, mobileNumber, name);
    if (pcs && pcs.length > 0) {
      console.log(pcs);
      if (peerId) {
        var condi: any = {peerId: peerId};
        peerClients = await this.find(condi, null, null, 0, 0);
        if (peerClients && peerClients.length > 0) {
          await this.devare(peerClients);
        }
      }
      if (mobileNumber) {
        var condi: any = {mobile: mobileNumber};
        peerClients = await this.find(condi, null, null, 0, 0);
        if (peerClients && peerClients.length > 0) {
          await this.devare(peerClients);
        }
      }
      if (name) {
        var condi: any = {name: name};
        peerClients = await this.find(condi, null, null, 0, 0);
        if (peerClients && peerClients.length > 0) {
          await this.devare(peerClients);
        }
      }
      peerClients = [];
      for (var pc of pcs) {
        if (pc.status === EntityStatus[EntityStatus.Effective]) {
          var peerClient = new PeerClient();
          peerClient.peerId = pc.peerId;
          peerClient.name = pc.name;
          peerClient.mobile = pc.mobile;
          peerClient.mobileVerified = pc.mobileVerified;
          peerClient.visibilitySetting = pc.visibilitySetting;
          peerClient.lastAccessTime = pc.lastAccessTime;
          peerClient.lastUpdateTime = pc.lastUpdateTime;
          peerClient.createDate = pc.createDate;
          peerClient.updateDate = pc.updateDate;
          peerClient.connectPeerId = pc.connectPeerId;
          peerClient.clientId = pc.clientId;
          peerClient.clientDevice = pc.clientDevice;
          peerClient.clientType = pc.clientType;
          peerClient.connectSessionId = pc.connectSessionId;
          peerClient.avatar = pc.avatar;
          peerClient.peerPublicKey = pc.peerPublicKey;
          peerClient.publicKey = pc.publicKey;
          peerClient.status = pc.status;
          peerClient.statusReason = pc.statusReason;
          peerClient.statusDate = pc.statusDate;
          peerClient.activeStatus = pc.activeStatus;
          await this.insert(peerClient);
          peerClients.push(peerClient);
        }
      }
    }
    return peerClients;
  }

Future<PeerClient>  getBestPeerClient(peerClients: PeerClient[], peerId: string) async {
    var best = undefined;
    if (peerClients && peerClients.length > 0) {
      for (var peerClient of peerClients) {
        if (peerClient) {
          if (!best) {
            best = peerClient;
          } else {
            var pcLastUpdateTime = new Date(peerClient.lastUpdateTime).getTime();
            var bestLastUpdateTime = new Date(best.lastUpdateTime).getTime();
            var pcLastAccessTime = new Date(peerClient.lastAccessTime).getTime();
            var bestLastAccessTime = new Date(best.lastAccessTime).getTime();
            if (pcLastUpdateTime > bestLastUpdateTime ||
              (pcLastUpdateTime === bestLastUpdateTime && pcLastAccessTime > bestLastAccessTime)) {
              best = peerClient;
            }
          }
        }
      }
    }
    if (best && peerId && best.peerId === peerId) {
      this.peerClients.set(peerId, best);
      if (best.publicKey) {
        var publicKey = await openpgp.import(best.publicKey);
        if (publicKey) {
          this.publicKeys.set(peerId, publicKey);
        }
      }
    }
    return best;
  }

Future<PeerClient>  findPeerClient(connectPeerId: string, peerId: string, mobileNumber: string, name: string): async {
    var peerClients = await this.getPeerClient(connectPeerId, peerId, mobileNumber, name);
    var best = await this.getBestPeerClient(peerClients, peerId);
    return best;
  }

Future<PeerClient>  preparePeerClient(connectPeerId: string, activeStatus: string) async  {
    if (!connectPeerId) {
      connectPeerId = config.appParams.connectPeerId[0];
    }
    if (!activeStatus) {
      activeStatus = ActiveStatus[ActiveStatus.Up];
    }
    var peerClient = new PeerClient();
    peerClient.peerId = myself.myselfPeer.peerId;
    peerClient.mobile = myself.myselfPeer.mobile;
    peerClient.name = myself.myselfPeer.name;
    peerClient.avatar = myself.myselfPeer.avatar;
    peerClient.peerPublicKey = myself.myselfPeer.peerPublicKey;
    peerClient.publicKey = myself.myselfPeer.publicKey;
    peerClient.lastUpdateTime = myself.myselfPeer.lastUpdateTime;
    peerClient.mobileVerified = myself.myselfPeer.mobileVerified;
    peerClient.visibilitySetting = myself.myselfPeer.visibilitySetting;
    peerClient.status = EntityStatus[EntityStatus.Effective];
    peerClient.connectPeerId = connectPeerId;
    peerClient.activeStatus = activeStatus;
    if (myself.peerProfile) {
      peerClient.clientId = myself.peerProfile.clientId;
      peerClient.clientType = myself.peerProfile.clientType;
      peerClient.clientDevice = myself.peerProfile.clientDevice;
      peerClient.deviceToken = myself.peerProfile.deviceToken;
      peerClient.language = myself.peerProfile.language;
    }

    var password = myself.password;
    peerClient.expireDate = new Date().getTime();
    peerClient.signatureData = peerClient.peerId;
    var signature = await openpgp.sign(peerClient.expireDate + peerClient.signatureData, myself.privateKey);
    peerClient.signature = signature;
    // 如有旧版本，设置expiredKeys，附上上个版本的签名
    var expiredKeys = [];
    var condi: any = {peerId: peerClient.peerId, status: EntityStatus[EntityStatus.Discarded], endDate: {$gt: null}};
    var expiredPeerClients = await myselfPeerService.find(condi, [{endDate: 'desc'}], null, 0, 0);
    if (expiredPeerClients && expiredPeerClients.length > 0) {
      for (var expiredPeerClient of expiredPeerClients) {
        var expiredPrivateKey_ = expiredPeerClient.privateKey;
        var expiredPrivateKey = null;
        try {
          expiredPrivateKey = await openpgp.import(expiredPrivateKey_, {password: password});
          if (expiredPrivateKey) {
            var isEncrypted = expiredPrivateKey.isEncrypted;
            console.log('isEncrypted:' + isEncrypted);
            if (isEncrypted) {
              await expiredPrivateKey.decrypt(password);
            }
          }
        } catch (e) {
          console.error('wrong password:' + e);
          return undefined;
        }
        var expiredPublicKey = await openpgp.import(expiredPeerClient.publicKey);
        expiredKeys.push({
          expiredPublicKey: expiredPublicKey,
          expiredPrivateKey: expiredPrivateKey
        });
      }
    }
    myself.expiredKeys = expiredKeys;
    if (myself.expiredKeys.length > 0) {
      var previousPublicKeySignature = await openpgp.sign(peerClient.expireDate + peerClient.signatureData, myself.expiredKeys[0].expiredPrivateKey);
      peerClient.previousPublicKeySignature = previousPublicKeySignature;
    }

    return peerClient;
  }

  /**
   * 把本地客户端信息发布到网上，第一个参数可以为空
   * @param connectPeerId
   * @param activeStatus
   */
  putPeerClient(connectPeerId: string, activeStatus: string) async {
    // 写自己的数据到peerendpoint中
    var peerClient = await this.preparePeerClient(connectPeerId, activeStatus);
    if (peerClient) {
      console.info('putPeerClient:' + peerClient.peerId + ';connectPeerId:' + connectPeerId + ';activeStatus:' + activeStatus);
      var result = await putValueAction.putValue(connectPeerId, PayloadType.PeerClient, peerClient);
      return result;
    }
  }

  /**
   * Connect
   */
   connect() async {
    var connectPeerId = config.appParams.connectPeerId[0];
    var activeStatus = ActiveStatus[ActiveStatus.Up];
    var peerClient = await this.preparePeerClient(connectPeerId, activeStatus);
    if (peerClient) {
      console.info('connect:' + peerClient.peerId + ';connectPeerId:' + connectPeerId);
      var result = await connectAction.connect(connectPeerId, peerClient);
      return result;
    }
  }
}
final peerClientService = PeerClientService.instance;