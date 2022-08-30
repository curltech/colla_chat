import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';

import '../../entity/dht/peerprofile.dart';
import '../../entity/dht/peersignal.dart';
import '../../tool/util.dart';
import '../../transport/webrtc/advanced_peer_connection.dart';
import '../general_base.dart';

enum SignalSource { local, remote }

class PeerSignalService extends GeneralBaseService<PeerSignal> {
  Map<String, Map<String, PeerProfile>> peerProfiles = {};

  PeerSignalService(
      {required String tableName,
      required List<String> fields,
      required List<String> indexFields})
      : super(tableName: tableName, fields: fields, indexFields: indexFields) {
    post = (Map map) {
      return PeerSignal.fromJson(map);
    };
  }

  Future<List<PeerSignal>> findByPeerId(String peerId,
      {String? clientId, String? signalType}) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    if (clientId != null) {
      where = '$where and clientId =?';
      whereArgs.add(clientId);
    }
    if (signalType != null) {
      where = '$where and signalType =?';
      whereArgs.add(signalType);
    }
    var peers = await find(where: where, whereArgs: whereArgs);

    return peers;
  }

  Future<PeerSignal?> findOneByPeerId(String peerId,
      {String? clientId, String? signalType}) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    if (clientId != null) {
      where = '$where and clientId =?';
      whereArgs.add(clientId);
    }
    if (signalType != null) {
      where = '$where and signalType =?';
      whereArgs.add(signalType);
    }
    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  modify(PeerSignal peerSignal) async {
    PeerSignal? old = await findOneByPeerId(peerSignal.peerId,
        clientId: peerSignal.clientId, signalType: peerSignal.signalType);
    if (old == null) {
      peerSignal.id = null;
      await insert(peerSignal);
    } else {
      peerSignal.id = old.id;
      await update(peerSignal);
    }
  }

  modifySignal(AdvancedPeerConnection advancedPeerConnection) async {
    var peerId = advancedPeerConnection.peerId;
    var clientId = advancedPeerConnection.clientId;
    advancedPeerConnection.basePeerConnection.initiator;
    var remoteSdp = advancedPeerConnection.basePeerConnection.remoteSdp;
    if (remoteSdp != null) {
      var peerSignal = PeerSignal(peerId, clientId!, remoteSdp.type!);
      var signal = WebrtcSignal(SignalType.sdp.name, sdp: remoteSdp);
      peerSignal.title = SignalSource.remote.name;
      peerSignal.content = JsonUtil.toJsonString(signal);
      await modify(peerSignal);
    }
    var localSdp = advancedPeerConnection.basePeerConnection.localSdp;
    if (localSdp != null) {
      var peerSignal =
          PeerSignal(myself.peerId!, myself.clientId!, localSdp.type!);
      var signal = WebrtcSignal(SignalType.sdp.name, sdp: localSdp);
      peerSignal.title = SignalSource.local.name;
      peerSignal.content = JsonUtil.toJsonString(signal);
      await modify(peerSignal);
    }
    var localCandidates =
        advancedPeerConnection.basePeerConnection.localCandidates;
    if (localCandidates.isNotEmpty) {
      var peerSignal = PeerSignal(
          myself.peerId!, myself.clientId!, SignalType.candidate.name);
      var signal =
          WebrtcSignal(SignalType.candidate.name, candidates: localCandidates);
      peerSignal.title = SignalSource.local.name;
      peerSignal.content = JsonUtil.toJsonString(signal);
      await modify(peerSignal);
    }
    var remoteCandidates =
        advancedPeerConnection.basePeerConnection.remoteCandidates;
    if (remoteCandidates.isNotEmpty) {
      var peerSignal = PeerSignal(peerId, clientId!, SignalType.candidate.name);
      var signal =
          WebrtcSignal(SignalType.candidate.name, candidates: remoteCandidates);
      peerSignal.title = SignalSource.remote.name;
      peerSignal.content = JsonUtil.toJsonString(signal);
      await modify(peerSignal);
    }
  }
}

final peerSignalService = PeerSignalService(
    tableName: "blc_peersignal",
    fields: ServiceLocator.buildFields(PeerSignal('', '', ''), []),
    indexFields: ['peerId', 'clientId', 'signalType']);
