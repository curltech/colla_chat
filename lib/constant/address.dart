import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/mail/mail_address.dart';

/// 配置文件的定位器
final Map<String, PeerEndpoint> nodeAddressOptions = {
  'default': PeerEndpoint(
    name: 'default',
    priority: 0,
    wsConnectAddress: 'wss://43.135.164.104:9090/websocket',
    httpConnectAddress: 'https://43.135.164.104:9091',
    peerId: '12D3KooWBiuFtWRQ5qrUmT5AFbJ6NXCqM9oKCMBUA3Dncm2mhLx8',
    libp2pConnectAddress:
        '/ip4/43.135.164.104/tcp/5720/wss/p2p/12D3KooWBiuFtWRQ5qrUmT5AFbJ6NXCqM9oKCMBUA3Dncm2mhLx8',
    iceServers: [
      {
        'url': 'stun:43.135.164.104:3478',
      },
      // {
      //   'url': 'turn:43.135.164.104:3478',
      // },
      //{"url": "stun:stun.l.google.com:19302"},
    ],
  ),
};
