import 'package:colla_chat/entity/chat/mailaddress.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';

/// 配置文件的定位器
final Map<String, PeerEndpoint> nodeAddressOptions = {
  'default': PeerEndpoint(
      name: 'default',
      priority: 0,
      wsConnectAddress: 'wss://localhost:9090/websocket',
      httpConnectAddress: 'https://localhost:9090',
      peerId: '12D3KooWJvWPnHcYPEG3oPwDcobfc2wzWJsgKV7fj5LC7qx15ihS',
      libp2pConnectAddress:
          '/ip4/127.0.0.1/tcp/5720/wss/p2p/12D3KooWJvWPnHcYPEG3oPwDcobfc2wzWJsgKV7fj5LC7qx15ihS',
      iceServers: [
        //{"url": "stun:stun.l.google.com:19302"},
        {
          'url': 'stun:localhost:3478',
        },
        // {
        //   'url': 'turn:localhost:3478',
        // }
      ]),
  'China-Shenzhen': PeerEndpoint(
      name: 'China-Shenzhen',
      wsConnectAddress: 'wss://sz.curltech.com.cn:9090/websocket',
      httpConnectAddress: 'https://sz.curltech.com.cn:9090',
      peerId: '12D3KooWFbyAYotJ3VtuDwCt1pkGdxGVxiW8PfiXsZ1NMqe1cKxJ',
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
  'China-Hangzhou': PeerEndpoint(
      name: 'China-Hangzhou',
      wsConnectAddress: 'wss://hz.curltech.com.cn:9090/websocket',
      httpConnectAddress: 'https://hz.curltech.com.cn:9090',
      peerId: '12D3KooWDTYWJ7bHXJFcEwq1NBJ2majgRjrY2xHjoMzSedkS3jgN',
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
  'South Korea': PeerEndpoint(
      name: 'South Korea',
      wsConnectAddress: 'wss://kr.curltech.cc:9090/websocket',
      httpConnectAddress: 'https://kr.curltech.cc:9090',
      peerId: '12D3KooWJk2AP2JcawJgScGPqtHXMaDwYUDBxNMjyGEEwPH3ghrD',
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
    email: 'hujs@colla.cc',
    name: 'hujs',
    domain: 'colla.cc',
    isDefault: true,
    imapServerHost: 'imaphz.qiye.163.com',
    popServerHost: 'pophz.qiye.163.com',
    smtpServerHost: 'smtphz.qiye.163.com',
  ),
  'hujs@curltech.io': MailAddress(
      email: 'hujs@curltech.io',
      name: 'hujs',
      domain: 'curltech.io',
      isDefault: true,
      imapServerHost: 'imaphz.qiye.163.com',
      popServerHost: 'pophz.qiye.163.com',
      smtpServerHost: 'smtphz.qiye.163.com'),
  '13609619603@163.com': MailAddress(
      email: '13609619603@163.com',
      name: 'hujs',
      domain: '163.com',
      isDefault: false,
      imapServerHost: 'imap.163.com',
      popServerHost: 'pop.163.com',
      smtpServerHost: 'smtp.163.com'),
  'hujs06@163.com': MailAddress(
      email: 'hujs06@163.com',
      name: 'hujs',
      domain: '163.com',
      isDefault: false,
      imapServerHost: 'imap.163.com',
      popServerHost: 'pop.163.com',
      smtpServerHost: 'smtp.163.com'),
};
