import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum AuthMethod { local, app, none }

class LocalAuthUtil {
  static final LocalAuthentication auth = LocalAuthentication();

  static Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool sensitiveTransaction = true,
    bool biometricOnly = false,
  }) async {
    bool authenticated = false;
    AuthenticationOptions options = AuthenticationOptions(
      useErrorDialogs: useErrorDialogs,
      stickyAuth: stickyAuth,
      biometricOnly: biometricOnly,
    );
    try {
      authenticated = await auth.authenticate(
        localizedReason: localizedReason,
        options: options,
      );
    } on PlatformException catch (e) {
      logger.e('local authenticate failure:$e');
    }

    return authenticated;
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await LocalAuthUtil.auth.getAvailableBiometrics();
    } on PlatformException {
      availableBiometrics = <BiometricType>[];
    }
    return availableBiometrics;
  }

  static Future<void> cancelAuthentication() async {
    await auth.stopAuthentication();
  }

  static Future<bool> canCheckBiometrics() async {
    bool canCheckBiometrics = await LocalAuthUtil.auth.canCheckBiometrics;

    return canCheckBiometrics;
  }

  static Future<bool> isDeviceSupported() async {
    bool isDeviceSupported = await LocalAuthUtil.auth.isDeviceSupported();

    return isDeviceSupported;
  }
}
