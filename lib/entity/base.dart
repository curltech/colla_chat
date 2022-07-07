///实体的业务状态
enum EntityStatus {
  draft,
  effective,
  expired,
  deleted,
  canceled,
  checking,
  undefined,
  locked,
  checked,
  unchecked,
  enabled,
  disable,
  discarded,
  merged,
  reversed,
}

///实体的脏标志，新增，删除，更新，
enum EntityState {
  insert,
  delete,
  update,
  none,
}

abstract class BaseEntity {
  int? id;
  String? createDate;
  String? updateDate;
  String? entityId;
  EntityState? state;

  BaseEntity();

  BaseEntity.fromJson(Map json)
      : id = json['id'] == '' ? null : json['id'],
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
