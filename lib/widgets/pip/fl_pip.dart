import 'package:fl_pip/fl_pip.dart';

class FlPipUtil {
  /// 开启画中画
  /// Open picture-in-picture
  void enable() {
    FlPiP().enable(
        ios: FlPiPiOSConfig(),
        android:
            FlPiPAndroidConfig(aspectRatio: const Rational.maxLandscape()));
  }

  /// 是否支持画中画
  /// Whether to support picture in picture
  void isAvailable() {
    FlPiP().isAvailable;
  }

  /// 画中画状态
  /// Picture-in-picture window state
  void isActive() {
    FlPiP().isActive;
  }

  /// 切换前后台
  /// Toggle front and back
  /// ios仅支持切换后台
  /// ios supports background switching only
  void toggle(AppState state) {
    FlPiP().toggle(state);
  }

  /// 退出画中画
  /// Quit painting in picture
  void disable() {
    FlPiP().disable();
  }
}
