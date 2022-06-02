import '../app.dart';
import 'base.dart';

/// 地址选择框的选项
final Map<String, NodeAddress> nodeAddressOptions = {
  'China-Shenzhen': NodeAddress('China-Shenzhen',
      wsConnectAddress: 'wss://sz.curltech.com.cn:9090/websocket',
      httpConnectAddress: 'https://sz.curltech.com.cn',
      connectPeerId: '12D3KooWFbyAYotJ3VtuDwCt1pkGdxGVxiW8PfiXsZ1NMqe1cKxJ',
      libp2pConnectAddress:
          '/dns4/sz.curltech.com.cn/tcp/5720/wss/p2p/12D3KooWFbyAYotJ3VtuDwCt1pkGdxGVxiW8PfiXsZ1NMqe1cKxJ'),
  'China-Hangzhou': NodeAddress('China-Hangzhou',
      wsConnectAddress: 'wss://hz.curltech.com.cn:9090/websocket',
      httpConnectAddress: 'https://hz.curltech.com.cn',
      connectPeerId: '12D3KooWDTYWJ7bHXJFcEwq1NBJ2majgRjrY2xHjoMzSedkS3jgN',
      libp2pConnectAddress:
          '/dns4/hz.curltech.com.cn/tcp/5720/wss/p2p/12D3KooWDTYWJ7bHXJFcEwq1NBJ2majgRjrY2xHjoMzSedkS3jgN'),
  'South Korea': NodeAddress('South Korea',
      wsConnectAddress: 'wss://kr.curltech.cc:9090/websocket',
      httpConnectAddress: 'https://kr.curltech.cc',
      connectPeerId: '12D3KooWJk2AP2JcawJgScGPqtHXMaDwYUDBxNMjyGEEwPH3ghrD',
      libp2pConnectAddress:
          '/dns4/kr.curltech.cc/tcp/5720/wss/p2p/12D3KooWJk2AP2JcawJgScGPqtHXMaDwYUDBxNMjyGEEwPH3ghrD')
};
