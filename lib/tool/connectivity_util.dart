import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityUtil {
  static Future<ConnectivityResult> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    return connectivityResult;
  }

  static StreamSubscription<ConnectivityResult> onConnectivityChanged(
      Function(ConnectivityResult result) onConnectivityChanged) {
    var subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      onConnectivityChanged(result);
    });

    return subscription;
  }

  static Future<void> cancel(
      StreamSubscription<ConnectivityResult> subscription) async {
    await subscription.cancel();
  }
}
