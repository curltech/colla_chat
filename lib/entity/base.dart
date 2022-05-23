import 'package:colla_chat/datastore/indexeddb.dart';
import 'package:colla_chat/tool/util.dart';
import '../../datastore/indexeddb.dart';
import '../../datastore/sqflite.dart';

import 'stock/account.dart';
import '../platform.dart';
import '../datastore/datastore.dart';

enum EntityStatus {
  Draft,
  Effective,
  Expired,
  Deleted,
  Canceled,
  Checking,
  Undefined,
  Locked,
  Checked,
  Unchecked,
  Enabled,
  Disable,
  Discarded,
  Merged,
  Reversed,
}

abstract class BaseEntity {
  int? id;
  String? createDate;
  String? updateDate;
  String? entityId;
  String? state;

  BaseEntity();

  BaseEntity.fromJson(Map json)
      : id = json['id'],
        createDate = json['createDate'],
        updateDate = json['updateDate'];

  Map<String, dynamic> toJson() =>
      {'id': id, 'createDate': createDate, 'updateDate': updateDate};
}

abstract class StatusEntity extends BaseEntity {
  String? status;
  String? statusReason;
  String? statusDate;

  StatusEntity();

  StatusEntity.fromJson(Map json)
      : status = json['status'],
        statusReason = json['statusReason'],
        statusDate = json['statusDate'],
        super.fromJson(json);

  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'status': status,
      'statusReason': statusReason,
      'statusDate': statusDate
    });
    return json;
  }
}
