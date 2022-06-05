/// webclient代表httpclient或者websocketclient
import 'package:colla_chat/transport/websocket.dart';
import 'httpclient.dart';

abstract class IWebClient {
  register(String name, Function func);

  dynamic send(String url, dynamic data);

  dynamic get(String url);
}

class WebClient extends IWebClient {
  static final WebClient _instance = WebClient();
  static bool initStatus = false;
  IWebClient? _httpDefault;
  IWebClient? _wsDefault;

  static WebClient get instance {
    if (!initStatus) {
      HttpClientPool httpClientPool = HttpClientPool.instance;
      WebsocketPool websocketPool = WebsocketPool.instance;
      _instance._httpDefault = httpClientPool.defaultHttpClient;
      _instance._wsDefault = websocketPool.defaultWebsocket;
      if (_instance._httpDefault == null && _instance._wsDefault == null) {
        throw 'NoDefaultWebClient';
      }
      initStatus = true;
    }
    return _instance;
  }

  setDefault(String address) async {
    if (address.startsWith('wss') || address.startsWith('ws')) {
      WebsocketPool websocketPool = WebsocketPool.instance;
      _wsDefault = websocketPool.setDefaultWebsocket(address);
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
