import '../entity/chat/mailaddress.dart';
import '../provider/app_data_provider.dart';

/// 地址选择框的选项
final Map<String, NodeAddress> nodeAddressOptions = {
  'default': NodeAddress('localhost',
      wsConnectAddress: 'wss://localhost:9090/websocket',
      httpConnectAddress: 'https://localhost:9090',
      connectPeerId: '12D3KooWGHzEzdyaet3Qk4mSVHcvXUh6CJTX8tCus9ZmrMXpi6HV',
      libp2pConnectAddress:
          '/ip4/127.0.0.1/tcp/5720/wss/p2p/12D3KooWGHzEzdyaet3Qk4mSVHcvXUh6CJTX8tCus9ZmrMXpi6HV',
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

/// 地址选择框的选项
final Map<String, MailAddress> mailAddressOptions = {
  'hujs@colla.cc': MailAddress(
    name: 'hujs',
    domain: 'colla.cc',
    isDefault: true,
    imapServerHost: 'imaphz.qiye.163.com',
    popServerHost: 'pophz.qiye.163.com',
    smtpServerHost: 'smtphz.qiye.163.com',
  ),
  'hujs@curltech.io': MailAddress(
      name: 'hujs',
      domain: 'curltech.io',
      isDefault: true,
      imapServerHost: 'imaphz.qiye.163.com',
      popServerHost: 'pophz.qiye.163.com',
      smtpServerHost: 'smtphz.qiye.163.com'),
  '13609619603@163.com': MailAddress(
      name: 'hujs',
      domain: '163.com',
      isDefault: false,
      imapServerHost: 'imap.163.com',
      popServerHost: 'pop.163.com',
      smtpServerHost: 'smtp.163.com'),
  'hujs06@163.com': MailAddress(
      name: 'hujs',
      domain: '163.com',
      isDefault: false,
      imapServerHost: 'imap.163.com',
      popServerHost: 'pop.163.com',
      smtpServerHost: 'smtp.163.com'),
};
