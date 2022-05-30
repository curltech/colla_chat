import 'base.dart';

/// 不同语言版本的地址选择框的选项
final libp2pAddressOptions = [
  Option('China-Shenzhen',
      '/dns4/sz.curltech.com.cn/tcp/5720/wss/p2p/12D3KooWFbyAYotJ3VtuDwCt1pkGdxGVxiW8PfiXsZ1NMqe1cKxJ'),
  Option('China-Hangzhou',
      '/dns4/hz.curltech.com.cn/tcp/5720/wss/p2p/12D3KooWDTYWJ7bHXJFcEwq1NBJ2majgRjrY2xHjoMzSedkS3jgN'),
  Option('South Korea',
      '/dns4/kr.curltech.cc/tcp/5720/wss/p2p/12D3KooWJk2AP2JcawJgScGPqtHXMaDwYUDBxNMjyGEEwPH3ghrD')
];

final libp2pAddressOptionsZH = [
  Option('中国-深圳', libp2pAddressOptions[0].value),
  Option('中国-杭州', libp2pAddressOptions[1].value),
  Option('韩国', libp2pAddressOptions[2].value)
];

final libp2pAddressOptionsTW = [
  Option('中國-深圳', libp2pAddressOptions[0].value),
  Option('中國-杭州', libp2pAddressOptions[1].value),
  Option('韓國', libp2pAddressOptions[2].value)
];

final libp2pAddressOptionsJA = [
  Option('中国-深セン', libp2pAddressOptions[0].value),
  Option('中国-杭州', libp2pAddressOptions[1].value),
  Option('韓国', libp2pAddressOptions[2].value)
];

final libp2pAddressOptionsKO = [
  Option('중국 - 심 천', libp2pAddressOptions[0].value),
  Option('중국 - 항주', libp2pAddressOptions[1].value),
  Option('한국', libp2pAddressOptions[2].value)
];

final libp2pAddressOptionsISO = {
  'zh_CN': libp2pAddressOptionsZH,
  'zh_TW': libp2pAddressOptionsTW,
  'en_US': libp2pAddressOptions,
  'ja_JP': libp2pAddressOptionsJA,
  'ko_KR': libp2pAddressOptionsKO
};

final wsAddressOptions = [
  Option('China-Shenzhen', 'wss://sz.curltech.com.cn'),
  Option('China-Hangzhou', 'wss://hz.curltech.com.cn'),
  Option('South Korea', 'wss://kr.curltech.cc'),
  //Option('Customize', ''),
];

final wsAddressOptionsZH = [
  Option('中国-深圳', wsAddressOptions[0].value),
  Option('中国-杭州', wsAddressOptions[1].value),
  Option('韩国', wsAddressOptions[2].value),
  //Option('自定义', ''),
];

final wsAddressOptionsTW = [
  Option('中國-深圳', wsAddressOptions[0].value),
  Option('中國-杭州', wsAddressOptions[1].value),
  Option('韓國', wsAddressOptions[2].value),
  //Option('自定义', ''),
];

final wsAddressOptionsJA = [
  Option('中国-深セン', wsAddressOptions[0].value),
  Option('中国-杭州', wsAddressOptions[1].value),
  Option('韓国', wsAddressOptions[2].value),
  //Option('自定义', ''),
];

final wsAddressOptionsKO = [
  Option('중국 - 심 천', wsAddressOptions[0].value),
  Option('중국 - 항주', wsAddressOptions[1].value),
  Option('한국', wsAddressOptions[2].value),
  //Option('自定义', ''),
];

final wsAddressOptionsISO = {
  'zh_CN': wsAddressOptionsZH,
  'zh_TW': wsAddressOptionsTW,
  'en_US': wsAddressOptions,
  'ja_JP': wsAddressOptionsJA,
  'ko_KR': wsAddressOptionsKO
};

final httpAddressOptions = [
  Option('China-Shenzhen', 'https://sz.curltech.com.cn'),
  Option('China-Hangzhou', 'https://hz.curltech.com.cn'),
  Option('South Korea', 'https://kr.curltech.cc')
];

final httpAddressOptionsZH = [
  Option('中国-深圳', httpAddressOptions[0].value),
  Option('中国-杭州', httpAddressOptions[1].value),
  Option('韩国', httpAddressOptions[2].value)
];

final httpAddressOptionsTW = [
  Option('中國-深圳', httpAddressOptions[0].value),
  Option('中國-杭州', httpAddressOptions[1].value),
  Option('韓國', httpAddressOptions[2].value)
];

final httpAddressOptionsJA = [
  Option('中国-深セン', httpAddressOptions[0].value),
  Option('中国-杭州', httpAddressOptions[1].value),
  Option('韓国', httpAddressOptions[2].value)
];

final httpAddressOptionsKO = [
  Option('중국 - 심 천', httpAddressOptions[0].value),
  Option('중국 - 항주', httpAddressOptions[1].value),
  Option('한국', httpAddressOptions[2].value)
];

final httpAddressOptionsISO = {
  'zh_CN': httpAddressOptionsZH,
  'zh_TW': httpAddressOptionsTW,
  'en_US': httpAddressOptions,
  'ja_JP': httpAddressOptionsJA,
  'ko_KR': httpAddressOptionsKO
};
