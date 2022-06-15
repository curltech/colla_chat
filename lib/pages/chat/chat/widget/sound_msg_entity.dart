class SoundMsgEntity {
  late int downloadFlag;
  late int duration;
  late String path;
  late List<String> urls;
  late int businessId;
  late int dataSize;
  late String type;
  late String uuid;
  late int taskId;

  SoundMsgEntity(
      {required this.downloadFlag,
      required this.duration,
      required this.path,
      required this.urls,
      required this.businessId,
      required this.dataSize,
      required this.type,
      required this.uuid,
      required this.taskId});

  SoundMsgEntity.fromJson(Map<String, dynamic> json) {
    downloadFlag = json['downloadFlag'];
    duration = json['duration'];
    path = json['path'];
    urls = json['urls']?.cast<String>();
    businessId = json['businessId'];
    dataSize = json['dataSize'];
    type = json['type'];
    uuid = json['uuid'];
    taskId = json['taskId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['downloadFlag'] = this.downloadFlag;
    data['duration'] = this.duration;
    data['path'] = this.path;
    data['urls'] = this.urls;
    data['businessId'] = this.businessId;
    data['dataSize'] = this.dataSize;
    data['type'] = this.type;
    data['uuid'] = this.uuid;
    data['taskId'] = this.taskId;
    return data;
  }
}
