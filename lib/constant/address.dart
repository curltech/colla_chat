import 'package:colla_chat/entity/chat/emailaddress.dart';
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
      //   'url': 'turn:43.155.159.73:3478',
      // },
      //{"url": "stun:stun.l.google.com:19302"},
    ],
  ),
};

/// 地址选择框的选项
final Map<String, EmailAddress> emailAddressOptions = {
  'hujs@colla.cc': EmailAddress(
    email: 'hujs@colla.cc',
    name: 'hujs',
    domain: 'colla.cc',
    isDefault: true,
    imapServerHost: 'imaphz.qiye.163.com',
    popServerHost: 'pophz.qiye.163.com',
    smtpServerHost: 'smtphz.qiye.163.com',
  ),
  'hujs@curltech.io': EmailAddress(
      email: 'hujs@curltech.io',
      name: 'hujs',
      domain: 'curltech.io',
      isDefault: true,
      imapServerHost: 'imaphz.qiye.163.com',
      popServerHost: 'pophz.qiye.163.com',
      smtpServerHost: 'smtphz.qiye.163.com'),
  '13609619603@163.com': EmailAddress(
      email: '13609619603@163.com',
      name: 'hujs',
      domain: '163.com',
      isDefault: false,
      imapServerHost: 'imap.163.com',
      popServerHost: 'pop.163.com',
      smtpServerHost: 'smtp.163.com'),
  'hujs06@163.com': EmailAddress(
      email: 'hujs06@163.com',
      name: 'hujs',
      domain: '163.com',
      isDefault: false,
      imapServerHost: 'imap.163.com',
      popServerHost: 'pop.163.com',
      smtpServerHost: 'smtp.163.com'),
};
