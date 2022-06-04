/// webclient代表httpclient或者websocketclient
import 'package:colla_chat/transport/websocket.dart';
import 'httpclient.dart';

abstract class IWebClient {
  register(String name, Function func);

  dynamic send(String url, dynamic data);

  dynamic get(String url);
}

class WebClient extends IWebClient {
  static WebClient instance = WebClient();
  static bool initStatus = false;
  IWebClient? _httpDefault;
  IWebClient? _wsDefault;

  static Future<WebClient> getInstance() async {
    if (!initStatus) {
      HttpClientPool httpClientPool = await HttpClientPool.getInstance();
      WebsocketPool websocketPool = await WebsocketPool.getInstance();
      instance._httpDefault = httpClientPool.defaultHttpClient;
      instance._wsDefault = websocketPool.defaultWebsocket;
      if (instance._httpDefault == null && instance._wsDefault == null) {
        throw 'NoDefaultWebClient';
      }
      initStatus = true;
    }
    return instance;
  }

  setDefault(String address) async {
    if (address.startsWith('wss') || address.startsWith('ws')) {
      WebsocketPool websocketPool = await WebsocketPool.getInstance();
      _wsDefault = websocketPool.setDefaultWebsocket(address);
    } else if (address.startsWith('https') || address.startsWith('http')) {
      if (address == 'https' || address == 'http') {
        HttpClientPool httpClientPool = await HttpClientPool.getInstance();
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
