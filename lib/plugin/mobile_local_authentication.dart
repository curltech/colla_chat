import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class MobileLocalAuthenticationPlugin {
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> init() async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    final List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();

    if (availableBiometrics.isNotEmpty) {
      // Some biometrics are enrolled.
    }

    if (availableBiometrics.contains(BiometricType.strong) ||
        availableBiometrics.contains(BiometricType.face)) {
      // Specific types of biometrics are available.
      // Use checks like this with caution!
    }

    authenticate() async {
      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to show account balance',
          authMessages: const <AuthMessages>[
            AndroidAuthMessages(
              signInTitle: 'Oops! Biometric authentication required!',
              cancelButton: 'No thanks',
            ),
            IOSAuthMessages(
              cancelButton: 'No thanks',
            ),
          ],
          biometricOnly: true,
          sensitiveTransaction: true,
          persistAcrossBackgrounding: false,
        );
        // ···
      } on PlatformException catch (e) {
        if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
          // Add handling of no hardware here.
        } else if (e.code == LocalAuthExceptionCode.biometricLockout) {
          // ...
        } else if (e.code == LocalAuthExceptionCode.temporaryLockout ||
            e.code == LocalAuthExceptionCode.deviceError) {
          // ...
        }
      }
    }
  }
}
