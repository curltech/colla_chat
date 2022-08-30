import '../base.dart';

/// 节点的webrtc signal信息，包括candidate，offer，answer
class PeerSignal extends StatusEntity {
  String peerId;
  String clientId;
  String signalType;

  // json串
  String? content;
  String? title;

  PeerSignal(this.peerId, this.clientId, this.signalType);

  PeerSignal.fromJson(Map json)
      : peerId = json['peerId'],
        clientId = json['clientId'],
        signalType = json['signalType'],
        content = json['content'],
        title = json['title'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId,
      'clientId': clientId,
      'signalType': signalType,
      'content': content,
      'title': title,
    });
    return json;
  }
}
