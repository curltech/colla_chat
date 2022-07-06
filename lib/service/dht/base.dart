import '../../entity/base.dart';
import '../base.dart';

abstract class PeerLocationService extends BaseService {
  Future<List<Map>> findByPeerId(String peerId) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    var peers = await find(where: where, whereArgs: whereArgs);

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
    var peers = await find(where: where, whereArgs: whereArgs);

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
    var peers = await find(where: where, whereArgs: whereArgs);

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
    var where = 'mail = ?';
    var whereArgs = [email];
    var peers = await find(where: where, whereArgs: whereArgs);

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
