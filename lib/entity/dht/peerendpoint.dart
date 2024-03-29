import 'package:colla_chat/tool/json_util.dart';

import 'base.dart';

class PeerEndpoint extends PeerEntity {
  String? endpointType;
  String? discoveryAddress;
  int priority = 1;
  String? lastConnectTime;
  String? wsConnectAddress;
  String? httpConnectAddress;
  String? libp2pConnectAddress;
  String? iceServers;
  String? uriHost;
  String? uriKey;
  String? uriSecret;

  PeerEndpoint({
    required String name,
    required String peerId,
    this.wsConnectAddress,
    this.httpConnectAddress,
    this.libp2pConnectAddress,
    this.priority = 1,
    List<Map<String, String>>? iceServers,
    this.uriHost,
    this.uriKey,
    this.uriSecret,
  }) : super(peerId, name) {
    if (iceServers != null) {
      this.iceServers = JsonUtil.toJsonString(iceServers);
    }
  }

  PeerEndpoint.fromJson(super.json)
      : endpointType = json['endpointType'],
        discoveryAddress = json['discoveryAddress'],
        priority = json['priority'] ?? 0,
        lastConnectTime = json['lastConnectTime'],
        wsConnectAddress = json['wsConnectAddress'],
        httpConnectAddress = json['httpConnectAddress'],
        libp2pConnectAddress = json['libp2pConnectAddress'],
        iceServers = json['iceServers'],
        uriHost = json['uriHost'],
        uriKey = json['uriKey'],
        uriSecret = json['uriSecret'],
        super.fromJson();

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
      'uriHost': uriHost,
      'uriKey': uriKey,
      'uriSecret': uriSecret,
    });
    return json;
  }

  void validate() {
    if (name == '') {
      throw 'NameFormatError';
    }
    var wsConnectAddress = this.wsConnectAddress;
    if (wsConnectAddress != null) {
      if (!wsConnectAddress.startsWith('wss') &&
          !wsConnectAddress.startsWith('ws')) {
        throw 'WsConnectAddressFormatError';
      }
    }
    var httpConnectAddress = this.httpConnectAddress;
    if (httpConnectAddress != null) {
      if (!httpConnectAddress.startsWith('https') &&
          !httpConnectAddress.startsWith('http')) {
        throw 'HttpConnectAddressFormatError';
      }
    }
    var libp2pConnectAddress = this.libp2pConnectAddress;
    if (libp2pConnectAddress != null) {
      if (!libp2pConnectAddress.startsWith('/dns') &&
          !libp2pConnectAddress.startsWith('/ip')) {
        throw 'Libp2pConnectAddressFormatError';
      }
    }
  }
}
