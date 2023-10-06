import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

/// 键盘可见性
class KeyboardVisibilityUtil {
  /// 键盘是否可见
  static bool isVisible() {
    var keyboardVisibilityController = KeyboardVisibilityController();

    return keyboardVisibilityController.isVisible;
  }

  /// 监听键盘可见性
  static StreamSubscription<bool> listen(Function(bool visible) onChange) {
    var keyboardVisibilityController = KeyboardVisibilityController();
    StreamSubscription<bool> keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      onChange(visible);
    });

    return keyboardSubscription;
  }

  /// 点击键盘消失的组件
  static keyboardDismissOnTap({
    Key? key,
    required Widget child,
    bool dismissOnCapturedTaps = false,
  }) {
    return KeyboardDismissOnTap(
      key: key,
      dismissOnCapturedTaps: dismissOnCapturedTaps,
      child: child,
    );
  }
}
