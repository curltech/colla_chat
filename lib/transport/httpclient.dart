import 'dart:io';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';

class DioHttpClient implements IWebClient {
  final Dio _client = Dio();
  String? _address;

  DioHttpClient(String address) {
    if (address.startsWith('http')) {
      ///获取dio中的httpclient，处理证书问题
      (_client.httpClientAdapter as IOHttpClientAdapter)
          .onHttpClientCreate = (HttpClient client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

        return client;
      };
      // Set default configs
      _client.options.baseUrl = address;
      _client.options.connectTimeout = const Duration(seconds: 5); //5s
      _client.options.receiveTimeout = const Duration(seconds: 1800);
      var token = '';
      var headers = {'Authorization': 'Bearer $token'};
      _client.options.headers = headers;
      _address = address;
    }

    // request interceptor
    _client.interceptors
        .add(InterceptorsWrapper(onResponse: (response, handler) {
      if (response.statusCode != 200) {
        logger.e(response.statusCode);
      }
      return handler.next(response);
    }, onError: (DioError e, handler) {
      logger.e(e.message);
      var statusCode = e.response?.statusCode;
      if (statusCode == 401) {
      } else if (statusCode == 500) {}
      return handler.next(e);
    }));
  }

  @override
  Future<Response> send(String url, dynamic data) {
    var response = _client.post(url, data: data);

    return response;
  }

  @override
  Future<Response> get(String url) {
    var response = _client.get(url);
    return response;
  }

  @override
  Function()? postConnected;
}

class HttpClientPool {
  static final HttpClientPool _instance = HttpClientPool();
  static bool initStatus = false;
  final _httpClients = <String, DioHttpClient>{};
  DioHttpClient? _default;

  HttpClientPool();

  /// 初始化连接池，设置缺省httpclient，返回连接池
  static HttpClientPool get instance {
    if (!initStatus) {
      var peerEndpoints = peerEndpointController.data;
      if (peerEndpoints.isNotEmpty) {
        int i = 0;
        for (var peerEndpoint in peerEndpoints) {
          var httpConnectAddress = peerEndpoint.httpConnectAddress;
          if (httpConnectAddress != null &&
              httpConnectAddress.startsWith('http')) {
            var httpClient = DioHttpClient(httpConnectAddress);
            _instance._httpClients[httpConnectAddress] = httpClient;
            if (i == 0) {
              _instance._default = httpClient;
            }
          }
          ++i;
        }
      }
      initStatus = true;
    }
    return _instance;
  }

  DioHttpClient? get(String address) {
    if (_httpClients.containsKey(address)) {
      return _httpClients[address];
    } else {
      var httpClient = DioHttpClient(address);
      _httpClients[address] = httpClient;

      return httpClient;
    }
  }

  DioHttpClient? get defaultHttpClient {
    return _default;
  }

  DioHttpClient? setDefalutHttpClient(String address) {
    DioHttpClient? httpClient;
    if (_httpClients.containsKey(address)) {
      httpClient = _httpClients[address];
    } else {
      httpClient = DioHttpClient(address);
      _httpClients[address] = httpClient;
    }
    _default = httpClient;

    return _default;
  }
}

final DefaultCacheManager defaultCacheManager = DefaultCacheManager();
