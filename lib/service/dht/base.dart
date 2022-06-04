import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:cryptography/cryptography.dart';

import '../../provider/app_data.dart';
import '../../crypto/cryptography.dart';
import '../../entity/base.dart';
import '../../entity/dht/base.dart';
import '../../entity/dht/myselfpeer.dart';
import '../../entity/dht/peerprofile.dart';
import '../../tool/util.dart';
import '../base.dart';
import 'myselfpeer.dart';

abstract class PeerLocationService extends BaseService {
  Future<List<Map>> findByPeerId(String peerId) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    var peers = await find(where, whereArgs: whereArgs);

    return peers;
  }

  Future<Map?> findOneEffectiveByPeerId(String peerId) async {
    var peers = await findByPeerId(peerId);
    if (peers.isNotEmpty) {
      for (var peer in peers) {
        if (peer['status'] == EntityStatus.Effective.name) {
          return peer;
        }
      }
    }

    return null;
  }

  Future<List<Map>> findByName(String name) async {
    var where = 'name = ?';
    var whereArgs = [name];
    var peers = await find(where, whereArgs: whereArgs);

    return peers;
  }

  Future<Map?> findOneEffectiveByName(String name) async {
    var peers = await findByName(name);
    if (peers.isNotEmpty) {
      for (var peer in peers) {
        if (peer['status'] == EntityStatus.Effective.name) {
          return peer;
        }
      }
    }

    return null;
  }
}

abstract class PeerEntityService extends PeerLocationService {
  Future<List<Map>> findByMobile(String mobile) async {
    var where = 'mobile = ?';
    var whereArgs = [mobile];
    var peers = await find(where, whereArgs: whereArgs);

    return peers;
  }

  Future<Map?> findOneEffectiveByMobile(String mobile) async {
    var peers = await findByMobile(mobile);
    if (peers.isNotEmpty) {
      for (var peer in peers) {
        if (peer['status'] == EntityStatus.Effective.name) {
          return peer;
        }
      }
    }

    return null;
  }

  Future<List<Map>> findByEmail(String email) async {
    var where = 'email = ?';
    var whereArgs = [email];
    var peers = await find(where, whereArgs: whereArgs);

    return peers;
  }

  Future<Map?> findOneEffectiveByEmail(String email) async {
    var peers = await findByEmail(email);
    if (peers.isNotEmpty) {
      for (var peer in peers) {
        if (peer['status'] == EntityStatus.Effective.name) {
          return peer;
        }
      }
    }

    return null;
  }
}
