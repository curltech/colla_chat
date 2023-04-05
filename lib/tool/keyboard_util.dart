import 'dart:async';

import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

/// Keyboard Visibility
/// KeyboardVisibilityBuilder isKeyboardVisible
/// KeyboardVisibilityProvider final bool isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(context);
/// KeyboardDismissOnTap dismissOnCapturedTaps: true,
class KeyboardVisibilityUtil {
  static bool isVisible() {
    var keyboardVisibilityController = KeyboardVisibilityController();

    return keyboardVisibilityController.isVisible;
  }

  static StreamSubscription<bool> listen(Function(bool visible) onChange) {
    var keyboardVisibilityController = KeyboardVisibilityController();
    StreamSubscription<bool> keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      onChange(visible);
    });

    return keyboardSubscription;
  }
}
