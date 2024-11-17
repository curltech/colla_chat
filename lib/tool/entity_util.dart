import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';

class EntityUtil {
  static Object? getId(dynamic entity) {
    if (entity is Map) {
      return entity['id'];
    } else {
      return entity.index;
    }
  }

  static setId(dynamic entity, Object val) {
    if (entity is Map) {
      entity['id'] = val;
    } else {
      entity.index = val;
    }
  }

  static bool? getChecked(dynamic entity) {
    if (entity is Map) {
      return entity['checked'];
    } else {
      return entity.checked;
    }
  }

  static setChecked(dynamic entity, bool? val) {
    if (entity is Map) {
      entity['checked'] = val;
    } else {
      entity.checked = val;
    }
  }

  static createTimestamp(dynamic entity) {
    var currentDate = DateUtil.currentDate();
    var ownerPeerId = myself.peerId;
    if (entity is Map) {
      entity['createDate'] = currentDate;
      entity['updateDate'] = currentDate;
      if (ownerPeerId != null) {
        entity['ownerPeerId'] = ownerPeerId;
      }
    } else {
      entity.createDate = currentDate;
      entity.updateDate = currentDate;
      if (ownerPeerId != null) {
        entity.ownerPeerId = ownerPeerId;
      }
    }
  }

  static dynamic updateTimestamp(dynamic entity) {
    var currentDate = DateUtil.currentDate();
    var ownerPeerId = myself.peerId;
    if (entity is Map) {
      Map<String, dynamic> map = {};
      map.addAll(entity as Map<String, dynamic>);
      map['updateDate'] = currentDate;
      if (ownerPeerId != null) {
        map['ownerPeerId'] = ownerPeerId;
      }

      return map;
    } else {
      entity.updateDate = currentDate;
      if (ownerPeerId != null) {
        entity.ownerPeerId = ownerPeerId;
      }

      return entity;
    }
  }

  static removeNullId(Map map) {
    var id = getId(map);
    if (id == null) {
      map.remove('id');
    }
  }

  static removeNull(Map map) {
    List<String> keys = [];
    for (var entry in map.entries) {
      String key = entry.key;
      var value = entry.value;
      if (value == null) {
        keys.add(key);
      } else {
        if (value is num) {
          if (value.isNaN || value.isInfinite) {
            keys.add(key);
          }
        }
      }
    }

    for (var key in keys) {
      map.remove(key);
    }
  }
}
