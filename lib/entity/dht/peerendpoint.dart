import 'base.dart';

class PeerEndpoint extends PeerEntity {
  String? endpointType;
  String? discoveryAddress;
  String? priority;
  String? ownerPeerId;
  String? lastConnectTime;

  PeerEndpoint();

  PeerEndpoint.fromJson(Map json)
      : endpointType = json['endpointType'],
        discoveryAddress = json['discoveryAddress'],
        priority = json['priority'],
        ownerPeerId = json['ownerPeerId'],
        lastConnectTime = json['lastConnectTime'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'endpointType': endpointType,
      'discoveryAddress': discoveryAddress,
      'priority': priority,
      'ownerPeerId': ownerPeerId,
      'lastConnectTime': lastConnectTime,
    });
    return json;
  }
}
