import '../base.dart';

/// app节点
class ChainApp extends StatusEntity {
  String? peerId;
  String? appType;
  String? registPeerId;
  String? path;
  String? mainClass;
  String? codePackage;
  String? appHash;
  String? appSignature;

  ChainApp.fromJson(Map json)
      : peerId = json['peerId'],
        appType = json['appType'],
        registPeerId = json['registPeerId'],
        path = json['path'],
        mainClass = json['mainClass'],
        codePackage = json['codePackage'],
        appHash = json['appHash'],
        appSignature = json['appSignature'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId,
      'appType': appType,
      'registPeerId': registPeerId,
      'path': path,
      'mainClass': mainClass,
      'codePackage': codePackage,
      'appHash': appHash,
      'appSignature': appSignature,
    });
    return json;
  }
}
