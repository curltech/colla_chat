import 'dart:async';

import 'package:colla_chat/platform.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkConnectivity {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  List<ConnectivityResult> connectivityResult = [];

  ///当前的网络连接状态，null:未连接;mobile:wifi:
  Future<String?> connective() async {
    List<ConnectivityResult> connectivityResult =
        await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.mobile) {
      return 'mobile';
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return 'wifi';
    }

    return null;
  }

  /// 注册连接状态监听器
  register([Function(List<ConnectivityResult> result)? fn]) {
    if (fn == null) {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } else {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(fn);
    }
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    connectivityResult = result;
  }
}

final networkConnectivity = NetworkConnectivity();

class NetworkInfoUtil {
  static NetworkInfo getWifiInfo() {
    // var wifiName = await info.getWifiName(); // FooNetwork
    // var wifiBSSID = await info.getWifiBSSID(); // 11:22:33:44:55:66
    // var wifiIP = await info.getWifiIP(); // 192.168.1.43
    // var wifiIPv6 = await info.getWifiIPv6(); // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
    // var wifiSubmask = await info.getWifiSubmask(); // 255.255.255.0
    // var wifiBroadcast = await info.getWifiBroadcast(); // 192.168.1.255
    // var wifiGateway = await info.getWifiGatewayIP(); // 192.168.1.1

    final info = NetworkInfo();

    return info;
  }

  static Future<String?> getWifiIp() async {
    if (!platformParams.web) {
      var info = getWifiInfo();
      var wifiIp = await info.getWifiIP(); // 192.168.1.43

      return wifiIp;
    }
    return null;
  }
}
