import 'package:colla_chat/entity/dht/peersignal.dart';
import 'package:colla_chat/service/servicelocator.dart';

import '../../entity/dht/peerprofile.dart';
import '../general_base.dart';

enum SignalSource { local, remote }

class PeerSignalService extends GeneralBaseService<PeerSignal> {
  Map<String, Map<String, PeerProfile>> peerProfiles = {};

  PeerSignalService(
      {required super.tableName,
      required super.fields,
      super.uniqueFields,
      super.indexFields = const ['peerId', 'clientId', 'signalType'],
      super.encryptFields}) {
    post = (Map map) {
      return PeerSignal.fromJson(map);
    };
  }

  Future<List<PeerSignal>> findByPeerId(String peerId,
      {String? clientId, String? signalType, String? title}) async {
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
    if (title != null) {
      where = '$where and title =?';
      whereArgs.add(title);
    }
    var peers = await find(where: where, whereArgs: whereArgs);

    return peers;
  }

  Future<PeerSignal?> findOneByPeerId(String peerId,
      {String? clientId, String? signalType, String? title}) async {
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
    if (title != null) {
      where = '$where and title =?';
      whereArgs.add(title);
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
}

final peerSignalService = PeerSignalService(
  tableName: "blc_peersignal",
  fields: ServiceLocator.buildFields(PeerSignal('', '', ''), []),
);
