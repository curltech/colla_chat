import 'package:colla_chat/provider/myself.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';


class NeumorphicConstants {
  NeumorphicShape get shape => NeumorphicShape.concave;

  LightSource get lightSource => LightSource.topLeft;

  NeumorphicBorder get border {
    return const NeumorphicBorder.none();
  }

  Color? get color => Colors.grey;

  NeumorphicBoxShape? get boxShape =>
      NeumorphicBoxShape.roundRect(BorderRadius.circular(12));

  double get depth => 8;

  double get intensity => 0.5;

  double get surfaceIntensity => 0.25;

  bool get oppositeShadowLightSource => false;

  NeumorphicStyle get style => NeumorphicStyle(
      shape: shape,
      boxShape: boxShape,
      depth: depth,
      lightSource: lightSource,
      color: color);

  ThemeMode get themeMode {
    return myself.themeMode;
  }

  NeumorphicThemeData get darkThemeData {
    var themeData = myself.themeData;
    Color primary = myself.primary;
    Color secondary = themeData.colorScheme.secondary;
    return NeumorphicThemeData(
      baseColor: primary,
      accentColor: secondary,
      lightSource: lightSource,
      depth: depth,
      intensity: intensity,
    );
  }

  NeumorphicThemeData get themeData {
    var themeData = myself.themeData;
    Color primary = themeData.colorScheme.primary;
    Color secondary = themeData.colorScheme.secondary;
    return NeumorphicThemeData(
      baseColor: primary,
      accentColor: secondary,
      lightSource: lightSource,
      depth: depth,
      intensity: intensity,
    );
  }

  NeumorphicTextStyle get textStyle {
    return NeumorphicTextStyle(
      fontSize: 18,
    );
  }
}

final neumorphicConstants = NeumorphicConstants();
