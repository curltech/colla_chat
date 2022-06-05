import '../provider/app_data.dart';

/// 地址选择框的选项
final Map<String, NodeAddress> nodeAddressOptions = {
  'default': NodeAddress('localhost',
      wsConnectAddress: 'wss://localhost:9090/websocket',
      httpConnectAddress: 'https://localhost:9090',
      connectPeerId: '12D3KooWPUFtWFhP2HbAKbGEo8Xfru4Y68su1e1so4Ndr5Xb1cF4',
      libp2pConnectAddress:
          '/ip4/127.0.0.1/tcp/5720/wss/p2p/12D3KooWPUFtWFhP2HbAKbGEo8Xfru4Y68su1e1so4Ndr5Xb1cF4',
      iceServers: [
        {
          'urls': 'stun:localhost:3478',
        },
        {
          'urls': 'turn:localhost:3478',
        }
      ]),
  'China-Shenzhen': NodeAddress('China-Shenzhen',
      wsConnectAddress: 'wss://sz.curltech.com.cn:9090/websocket',
      httpConnectAddress: 'https://sz.curltech.com.cn:9090',
      connectPeerId: '12D3KooWFbyAYotJ3VtuDwCt1pkGdxGVxiW8PfiXsZ1NMqe1cKxJ',
      libp2pConnectAddress:
          '/dns4/sz.curltech.com.cn/tcp/5720/wss/p2p/12D3KooWFbyAYotJ3VtuDwCt1pkGdxGVxiW8PfiXsZ1NMqe1cKxJ',
      iceServers: [
        {
          'urls': 'stun:sz.curltech.com.cn:3478',
        },
        {
          'urls': 'turn:sz.curltech.com.cn:3478',
        }
      ]),
  'China-Hangzhou': NodeAddress('China-Hangzhou',
      wsConnectAddress: 'wss://hz.curltech.com.cn:9090/websocket',
      httpConnectAddress: 'https://hz.curltech.com.cn:9090',
      connectPeerId: '12D3KooWDTYWJ7bHXJFcEwq1NBJ2majgRjrY2xHjoMzSedkS3jgN',
      libp2pConnectAddress:
          '/dns4/hz.curltech.com.cn/tcp/5720/wss/p2p/12D3KooWDTYWJ7bHXJFcEwq1NBJ2majgRjrY2xHjoMzSedkS3jgN',
      iceServers: [
        {
          'urls': 'stun:hz.curltech.com.cn:3478',
        },
        {
          'urls': 'turn:hz.curltech.com.cn:3478',
        }
      ]),
  'South Korea': NodeAddress('South Korea',
      wsConnectAddress: 'wss://kr.curltech.cc:9090/websocket',
      httpConnectAddress: 'https://kr.curltech.cc:9090',
      connectPeerId: '12D3KooWJk2AP2JcawJgScGPqtHXMaDwYUDBxNMjyGEEwPH3ghrD',
      libp2pConnectAddress:
          '/dns4/kr.curltech.cc/tcp/5720/wss/p2p/12D3KooWJk2AP2JcawJgScGPqtHXMaDwYUDBxNMjyGEEwPH3ghrD',
      iceServers: [
        {
          'urls': 'stun:kr.curltech.cc:3478',
        },
        {
          'urls': 'turn:kr.curltech.cc:3478',
        }
      ])
};
