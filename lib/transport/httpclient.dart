import 'package:colla_chat/transport/webclient.dart';
import 'package:dio/dio.dart';

import '../config.dart';

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
      if (response.statusCode != 200) {}
      return handler.next(response);
    }, onError: (DioError e, handler) {
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
  final _httpClients = <String, HttpClient>{};
  HttpClient? _default;

  HttpClientPool() {
    var connectAddress = config.appParams.httpConnectAddress;
    int i = 0;
    for (var address in connectAddress) {
      if (address.startsWith('http')) {
        var httpClient = HttpClient(address);
        _httpClients[address] = httpClient;
        if (i == 0) {
          _default ??= httpClient;
        }
      }
      i++;
    }
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

  setDefalutHttpClient(String address) {
    HttpClient? httpClient;
    if (_httpClients.containsKey(address)) {
      httpClient = _httpClients[address];
    } else {
      httpClient = HttpClient(address);
      this._httpClients[address] = httpClient;
    }

    _default = httpClient;
  }
}

final httpClientPool = HttpClientPool();
