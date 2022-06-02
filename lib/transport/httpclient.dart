import 'dart:html';

import 'package:colla_chat/transport/webclient.dart';
import 'package:dio/dio.dart';

import '../app.dart';

class HttpClient implements IWebClient {
  Dio _client = Dio();
  String? _address;

  HttpClient(String address) {
    if (address.startsWith('http')) {
      // Set default configs
      _client.options.baseUrl = address;
      _client.options.connectTimeout = 5000; //5s
      _client.options.receiveTimeout = 1800000;
      var token = '';
      var headers = {'Authorization': 'Bearer $token'};
      _client.options.headers = headers;
      _address = address;
    }

    // request interceptor
    _client.interceptors
        .add(InterceptorsWrapper(onResponse: (response, handler) {
      if (response.statusCode != 200) {
        print(response.statusCode);
      }
      return handler.next(response);
    }, onError: (DioError e, handler) {
      print(e.message);
      var statusCode = e.response?.statusCode;
      if (statusCode == 401) {
      } else if (statusCode == 500) {}
      return handler.next(e);
    }));
  }

  @override
  dynamic send(String url, dynamic data) {
    var response = _client.post(url, data: data);

    return response;
  }

  @override
  dynamic get(String url) {
    var response = _client.get(url);
    return response;
  }

  @override
  register(String name, Function func) {}
}

class HttpClientPool {
  static HttpClientPool instance = HttpClientPool();
  static bool initStatus = false;
  final _httpClients = <String, HttpClient>{};
  HttpClient? _default;

  HttpClientPool();

  /// 初始化连接池，设置缺省httpclient，返回连接池
  static Future<HttpClientPool> getInstance() async {
    if (!initStatus) {
      var appParams = AppParams.instance;
      var nodeAddress = appParams.nodeAddress;
      if (nodeAddress.isNotEmpty) {
        for (var address in nodeAddress.entries) {
          var name = address.key;
          var httpConnectAddress = address.value.httpConnectAddress;
          if (httpConnectAddress != null &&
              httpConnectAddress.startsWith('http')) {
            var httpClient = HttpClient(httpConnectAddress);
            instance._httpClients[httpConnectAddress] = httpClient;
            if (name == NodeAddress.defaultName) {
              instance._default = httpClient;
            }
          }
        }
      }
      initStatus = true;
    }
    return instance;
  }

  HttpClient? get(String address) {
    if (_httpClients.containsKey(address)) {
      return _httpClients[address];
    } else {
      var httpClient = HttpClient(address);
      _httpClients[address] = httpClient;

      return httpClient;
    }
  }

  HttpClient? get defaultHttpClient {
    return _default;
  }

  HttpClient? setDefalutHttpClient(String address) {
    HttpClient? httpClient;
    if (_httpClients.containsKey(address)) {
      httpClient = _httpClients[address];
    } else {
      httpClient = HttpClient(address);
      _httpClients[address] = httpClient;
    }
    _default = httpClient;

    return _default;
  }
}
