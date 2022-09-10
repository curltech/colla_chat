import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/tool/date_util.dart';

class EntityUtil {
  static Object? getId(dynamic entity) {
    if (entity is Map) {
      return entity['id'];
    } else {
      return entity.id;
    }
  }

  static setId(dynamic entity, Object val) {
    if (entity is Map) {
      entity['id'] = val;
    } else {
      entity.id = val;
    }
  }

  static createTimestamp(dynamic entity) {
    var currentDate = DateUtil.currentDate();
    var ownerPeerId = myself.peerId;
    if (entity is Map) {
      entity['createDate'] = currentDate;
      entity['updateDate'] = currentDate;
      entity['ownerPeerId'] = ownerPeerId;
    } else {
      entity.createDate = currentDate;
      entity.updateDate = currentDate;
      entity.ownerPeerId = ownerPeerId;
    }
  }

  static updateTimestamp(dynamic entity) {
    var currentDate = DateUtil.currentDate();
    if (entity is Map) {
      entity['updateDate'] = currentDate;
    } else {
      entity.updateDate = currentDate;
    }
  }

  static removeNullId(Map map) {
    var id = getId(map);
    if (id == null) {
      map.remove('id');
    }
  }

  static removeNull(Map map) {
    map.removeWhere((key, value) => value == null);
  }
}
