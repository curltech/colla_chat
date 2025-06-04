import 'package:colla_chat/entity/dht/peerendpoint.dart';

const String serverAddress = '192.168.1.122'; //'43.155.159.73';
const String serverPeerId =
    '12D3KooWSgYw3ebDJXGjZKap4ygtFTxvFHSj7dYDQWCVkcSZB2KJ'; //'12D3KooWBiuFtWRQ5qrUmT5AFbJ6NXCqM9oKCMBUA3Dncm2mhLx8'
/// 配置文件的定位器
final Map<String, PeerEndpoint> nodeAddressOptions = {
  'default': PeerEndpoint(
    name: 'default',
    priority: 0,
    wsConnectAddress: 'wss://$serverAddress:9090/websocket',
    httpConnectAddress: 'https://$serverAddress:9091',
    peerId: serverPeerId,
    libp2pConnectAddress: '/ip4/$serverAddress/tcp/5720/wss/p2p/$serverPeerId',
    iceServers: [
      {
        'url': 'stun:$serverAddress:3478',
      },
      // {
      //   'url': 'turn:43.135.164.104:3478',
      // },
      //{"url": "stun:stun.l.google.com:19302"},
    ],
  ),
};
