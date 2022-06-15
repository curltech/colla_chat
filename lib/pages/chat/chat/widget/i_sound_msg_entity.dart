class ISoundMsgEntity {
  late int downloadFlag;
  late String path;
  late int businessId;
  late int dataSize;
  late List<String> soundUrls;
  late String uuid;
  late int taskId;
  late int second;

  ISoundMsgEntity(
      {required this.downloadFlag,
      required this.path,
      required this.businessId,
      required this.dataSize,
      required this.soundUrls,
      required this.uuid,
      required this.taskId,
      required this.second});

  ISoundMsgEntity.fromJson(Map<String, dynamic> json) {
    downloadFlag = json['downloadFlag'];
    path = json['path'];
    businessId = json['businessId'];
    dataSize = json['dataSize'];
    soundUrls = json['soundUrls']?.cast<String>();
    uuid = json['uuid'];
    taskId = json['taskId'];
    second = json['second'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['downloadFlag'] = this.downloadFlag;
    data['path'] = this.path;
    data['businessId'] = this.businessId;
    data['dataSize'] = this.dataSize;
    data['soundUrls'] = this.soundUrls;
    data['uuid'] = this.uuid;
    data['taskId'] = this.taskId;
    data['second'] = this.second;
    return data;
  }
}
