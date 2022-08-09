import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';

class MobileLocalAuthenticationPlugin {
  final LocalAuthentication auth = LocalAuthentication();

  init() async {
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
            options: const AuthenticationOptions(
                biometricOnly: true, useErrorDialogs: false));
        // ···
      } on PlatformException catch (e) {
        if (e.code == auth_error.notAvailable) {
          // Add handling of no hardware here.
        } else if (e.code == auth_error.notEnrolled) {
          // ...
        } else if (e.code == auth_error.lockedOut ||
            e.code == auth_error.permanentlyLockedOut) {
          // ...
        }
      }
    }
  }
}
