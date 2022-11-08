import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/tool/image_util.dart';

import '../../entity/base.dart';

abstract class PeerLocationService<T> extends GeneralBaseService<T> {
  PeerLocationService(
      {required super.tableName,
      required super.fields,
      required super.indexFields});

  Future<List<T>> findByPeerId(String peerId) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    var peers = await find(where: where, whereArgs: whereArgs);

    return peers;
  }

  Future<T?> findOneByPeerId(String peerId) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];

    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  Future<List<T>> findByName(String name) async {
    var where = 'name = ?';
    var whereArgs = [name];
    var peers = await find(where: where, whereArgs: whereArgs);

    return peers;
  }

  Future<T?> findOneByName(String name) async {
    var where = 'name = ?';
    var whereArgs = [name];

    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  Future<int> deleteByPeerId(String peerId) async {
    var count = await delete({'peerId': peerId});

    return count;
  }
}

abstract class PeerEntityService<T> extends PeerLocationService<T> {
  PeerEntityService(
      {required super.tableName,
      required super.fields,
      required super.indexFields});

  Future<List<T>> findByMobile(String mobile) async {
    var where = 'mobile = ?';
    var whereArgs = [mobile];
    var peers = await find(where: where, whereArgs: whereArgs);

    return peers;
  }

  Future<T?> findOneEffectiveByMobile(String mobile) async {
    var where = 'mobile = ? and status=?';
    var whereArgs = [mobile, EntityStatus.effective.name];
    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  Future<List<T>> findByEmail(String email) async {
    var where = 'mail = ?';
    var whereArgs = [email];
    var peers = await find(where: where, whereArgs: whereArgs);

    return peers;
  }

  Future<T?> findOneEffectiveByEmail(String email) async {
    var where = 'mail = ? and status=?';
    var whereArgs = [email, EntityStatus.effective.name];
    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  Future<String> updateAvatar(int id, List<int> avatar) async {
    String data = CryptoUtil.encodeBase64(avatar);
    data = ImageUtil.base64Img(data);
    await update({'id': id, 'avatar': data});

    return data;
  }
}
