/**
 * webclient代表httpclient或者websocketclient
 */
import 'package:colla_chat/transport/websocket.dart';

import '../config.dart';
import '../tool/util.dart';
import 'httpclient.dart';

abstract class IWebClient {
  register(String name, Function func);

  dynamic send(String url, dynamic data);

  dynamic get(String url);
}

class WebClient extends IWebClient {
  IWebClient? _httpDefault;
  IWebClient? _wsDefault;

  IWebClient? get defaultClient {
    if (_wsDefault != null) {
      return _wsDefault;
    } else {
      return _httpDefault;
    }
  }

  set setDefaultClient(String address) {
    if (address.startsWith('wss') || address.startsWith('ws')) {
      if (address == 'wss' || address == 'ws') {
        var cas = config.appParams.wsConnectAddress;
        if (cas.isNotEmpty) {
          websocketPool.setDefalutWebsocket(cas[0]);
        }
      } else {
        websocketPool.setDefalutWebsocket(address);
      }
      _wsDefault = websocketPool.defaultWebsocket;
    } else if (address.startsWith('https') || address.startsWith('http')) {
      if (address == 'https' || address == 'http') {
        var cas = config.appParams.httpConnectAddress;
        if (cas.isNotEmpty) {
          httpClientPool.setDefalutHttpClient(cas[0]);
        }
      } else {
        httpClientPool.setDefalutHttpClient(address);
      }
      _httpDefault = httpClientPool.defaultHttpClient;
    }
  }

  register(String name, Function func) {
    if (_wsDefault != null) {
      _wsDefault?.register(name, func);
    }
  }

  dynamic send(String url, dynamic data) {
    if (_wsDefault != null) {
      return _wsDefault?.send(url, data);
    } else if (_httpDefault != null) {
      return _httpDefault?.send(url, data);
    } else {
      throw 'NoWebClient';
    }
  }

  dynamic get(String url) {
    return this.send(url, {});
  }
}

final webClient = WebClient();
