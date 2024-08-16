import 'package:colla_chat/entity/dht/peerendpoint.dart';

/// 配置文件的定位器
final Map<String, PeerEndpoint> nodeAddressOptions = {
  'default': PeerEndpoint(
    name: 'default',
    priority: 0,
    wsConnectAddress: 'wss://43.155.159.73:9090/websocket',
    httpConnectAddress: 'https://43.155.159.73:9091',
    peerId: '12D3KooWBiuFtWRQ5qrUmT5AFbJ6NXCqM9oKCMBUA3Dncm2mhLx8',
    libp2pConnectAddress:
        '/ip4/43.155.159.73/tcp/5720/wss/p2p/12D3KooWBiuFtWRQ5qrUmT5AFbJ6NXCqM9oKCMBUA3Dncm2mhLx8',
    iceServers: [
      {
        'url': 'stun:43.155.159.73:3478',
      },
      // {
      //   'url': 'turn:43.135.164.104:3478',
      // },
      //{"url": "stun:stun.l.google.com:19302"},
    ],
  ),
};
