import 'dart:io';

import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

class DioHttpClient implements IWebClient {
  final Dio _client = Dio();

  DioHttpClient(String address) {
    if (address.startsWith('http')) {
      ///获取dio中的httpclient，处理证书问题
      (_client.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        /// 解决Connection closed before full header was received错误
        final context = SecurityContext.defaultContext;
        context.allowLegacyUnsafeRenegotiation = true;
        final client = HttpClient(context: context);
        client.findProxy = (url) {
          // ///设置代理 电脑ip地址
          // return "PROXY 192.168.31.102:8888";
          ///不设置代理
          return 'DIRECT';
        };
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

        return client;
      };
      // Set default configs
      // _client.options.persistentConnection = false;
      _client.options.baseUrl = address;
      _client.options.connectTimeout = const Duration(seconds: 5); //5s
      _client.options.receiveTimeout = const Duration(seconds: 1800);
      var token = '';
      var headers = {'Authorization': 'Bearer $token'};
      _client.options.headers = headers;
    }

    // request interceptor
    _client.interceptors.add(RetryInterceptor(
      dio: _client,
    ));
    _client.interceptors
        .add(InterceptorsWrapper(onResponse: (response, handler) {
      if (response.statusCode != 200) {
        logger.e(response.statusCode.toString());
      }
      return handler.next(response);
    }, onError: (DioException e, handler) {
      logger.e(e.message.toString());
      var statusCode = e.response?.statusCode;
      if (statusCode == 401) {
      } else if (statusCode == 500) {}
      return handler.next(e);
    }));
  }

  @override
  Future<Response> send(String url, dynamic data) async {
    var response = await _client.post(url, data: data);

    return response;
  }

  @override
  Future<Response> get(String url) async {
    var response = await _client.get(url);
    return response;
  }

  @override
  Function()? postConnected;
}

class HttpClientPool {
  final _httpClients = <String, DioHttpClient>{};
  DioHttpClient? _default;

  HttpClientPool() {
    var peerEndpoints = peerEndpointController.data;
    if (peerEndpoints.isNotEmpty) {
      int i = 0;
      for (var peerEndpoint in peerEndpoints) {
        var httpConnectAddress = peerEndpoint.httpConnectAddress;
        if (httpConnectAddress != null &&
            httpConnectAddress.startsWith('http')) {
          var httpClient = DioHttpClient(httpConnectAddress);
          _httpClients[httpConnectAddress] = httpClient;
          if (i == 0) {
            _default = httpClient;
          }
        }
        ++i;
      }
    }
  }

  DioHttpClient get(String address) {
    if (_httpClients.containsKey(address)) {
      return _httpClients[address]!;
    } else {
      var httpClient = DioHttpClient(address);
      _httpClients[address] = httpClient;

      return httpClient;
    }
  }

  DioHttpClient? get defaultHttpClient {
    return _default;
  }

  DioHttpClient? setDefaultHttpClient(String address) {
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

final HttpClientPool httpClientPool = HttpClientPool();
final DefaultCacheManager defaultCacheManager = DefaultCacheManager();
