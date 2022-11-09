/// webclient代表httpclient或者websocketclient
import 'package:colla_chat/transport/websocket.dart';

import 'httpclient.dart';

abstract class IWebClient {
  register(String name, Function func);

  dynamic send(String url, dynamic data);

  dynamic get(String url);
}

class WebClient extends IWebClient {
  IWebClient? _httpDefault;
  IWebClient? _wsDefault;

  WebClient() {
    HttpClientPool httpClientPool = HttpClientPool.instance;
    _httpDefault = httpClientPool.defaultHttpClient;
    _wsDefault = websocketPool.getDefault();
    if (_httpDefault == null && _wsDefault == null) {
      throw 'NoDefaultWebClient';
    }
  }

  setDefault(String address) async {
    if (address.startsWith('wss') || address.startsWith('ws')) {
      _wsDefault = await websocketPool.get(address, isDefault: true);
    } else if (address.startsWith('https') || address.startsWith('http')) {
      if (address == 'https' || address == 'http') {
        HttpClientPool httpClientPool = HttpClientPool.instance;
        _httpDefault = httpClientPool.setDefalutHttpClient(address);
      }
    }
  }

  @override
  register(String name, Function func) {
    if (_wsDefault != null) {
      _wsDefault?.register(name, func);
    }
  }

  @override
  dynamic send(String url, dynamic data) {
    if (_wsDefault != null) {
      return _wsDefault?.send(url, data);
    } else if (_httpDefault != null) {
      return _httpDefault?.send(url, data);
    } else {
      throw 'NoWebClient';
    }
  }

  @override
  dynamic get(String url) {
    return send(url, {});
  }
}

final WebClient webClient = WebClient();
