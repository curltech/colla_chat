import 'base.dart';

class PeerEndpoint extends PeerEntity {
  String? endpointType;
  String? discoveryAddress;
  String? priority;
  String? lastConnectTime;
  String? wsConnectAddress;
  String? httpConnectAddress;
  String? libp2pConnectAddress;
  String? iceServers;

  PeerEndpoint(String peerId, String name) : super(peerId, name);

  PeerEndpoint.fromJson(Map json)
      : endpointType = json['endpointType'],
        discoveryAddress = json['discoveryAddress'],
        priority = json['priority'],
        lastConnectTime = json['lastConnectTime'],
        wsConnectAddress = json['wsConnectAddress'],
        httpConnectAddress = json['httpConnectAddress'],
        libp2pConnectAddress = json['libp2pConnectAddress'],
        iceServers = json['iceServers'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'endpointType': endpointType,
      'discoveryAddress': discoveryAddress,
      'priority': priority,
      'lastConnectTime': lastConnectTime,
      'wsConnectAddress': wsConnectAddress,
      'httpConnectAddress': httpConnectAddress,
      'libp2pConnectAddress': libp2pConnectAddress,
      'iceServers': iceServers,
    });
    return json;
  }
}
