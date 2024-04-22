import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityUtil {
  static Future<List<ConnectivityResult>> checkConnectivity() async {
    List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    return connectivityResult;
  }

  static ConnectivityResult getMainResult(
      List<ConnectivityResult> connectivityResult) {
    if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      return ConnectivityResult.vpn;
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      return ConnectivityResult.bluetooth;
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      return ConnectivityResult.other;
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      return ConnectivityResult.none;
    }

    return ConnectivityResult.none;
  }

  static StreamSubscription<List<ConnectivityResult>> onConnectivityChanged(
      Function(List<ConnectivityResult> result) onConnectivityChanged) {
    var subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      onConnectivityChanged(result);
    });

    return subscription;
  }

  static Future<void> cancel(
      StreamSubscription<List<ConnectivityResult>> subscription) async {
    await subscription.cancel();
  }
}
