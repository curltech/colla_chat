import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityUtil {
  static Future<List<ConnectivityResult>> checkConnectivity() async {
    List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    return connectivityResult;
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
      StreamSubscription<ConnectivityResult> subscription) async {
    await subscription.cancel();
  }
}
