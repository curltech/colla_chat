import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphic_ui_kit/glassmorphic_ui_kit.dart' as glass;

/// glassmorphic_ui_kit实现，提供了多个个glass化的Widget
final defaultLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withAlpha(AppOpacity.lgOpacity),
      Colors.white.withAlpha(AppOpacity.xlOpacity),
    ],
    stops: const [
      0.3,
      0.9,
    ]);

extension GlassmorphicKitWidget<T extends Widget> on T {
  Widget asGlassmorphicKit(
      {Key? key,
      double? height,
      double? width,
      EdgeInsetsGeometry? padding,
      Gradient? gradient,
      Color? color,
      BorderRadius? borderRadius = defaultBorderRadius,
      BoxBorder? border,
      double blur = defaultBlur,
      double opacity = defaultOpacity}) {
    return glass.GlassContainer(
      key: key,
      width: width,
      height: height,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      border: border,
      color: color,
      padding: padding,
      child: this,
    );
  }
}

/// glass的实现，使用比较方便，调用asGlass
class GlassmorphicKitContainer extends glass.GlassContainer {
  const GlassmorphicKitContainer(
      {super.key,
      super.width,
      super.height,
      super.blur = glass.GlassConstants.defaultBlur,
      super.opacity = glass.GlassConstants.defaultOpacity,
      super.borderRadius,
      super.gradient,
      super.border,
      super.color,
      super.padding,
      required super.child});
}

class GlassmorphicKitButton extends glass.GlassButton {
  const GlassmorphicKitButton({
    super.key,
    required super.child,
    super.onPressed,
    super.blur = glass.GlassConstants.defaultBlur,
    super.opacity = glass.GlassConstants.defaultOpacity,
    super.borderRadius,
    super.padding,
    super.gradient,
    super.enabled = true,
    super.animationDuration = const Duration(milliseconds: 200),
  });
}

class GlassmorphicKitCard extends glass.GlassCard {
  const GlassmorphicKitCard({
    super.key,
    required super.child,
    super.blur = glass.GlassConstants.defaultBlur,
    super.opacity = glass.GlassConstants.defaultOpacity,
    super.borderRadius,
    super.padding,
    super.margin,
    super.gradient,
    super.width,
    super.height,
    super.onTap,
    super.shadow,
  });
}

class GlassmorphicKitDialog extends glass.GlassDialog {
  const GlassmorphicKitDialog({
    super.key,
    super.title,
    super.content,
    super.actions,
    super.blur = 10,
    super.borderRadius,
    super.gradient,
  });
}

class GlassmorphicKitBottomSheet extends glass.GlassBottomSheet {
  const GlassmorphicKitBottomSheet({
    super.key,
    required super.child,
    super.blur = 10,
    super.height,
    super.borderRadius,
    super.gradient,
    super.padding,
  });
}

class GlassmorphicKitNavigationBar extends glass.GlassNavigationBar {
  const GlassmorphicKitNavigationBar({
    super.key,
    required super.destinations,
    required super.selectedIndex,
    super.onDestinationSelected,
    super.blur = glass.GlassConstants.defaultBlur,
    super.opacity = glass.GlassConstants.defaultOpacity,
    super.height = 80.0,
    super.borderRadius,
    super.gradient,
    super.padding,
    super.animateLabels = true,
    super.labelBehavior = NavigationDestinationLabelBehavior.alwaysShow,
  });
}

class GlassmorphicKitNavigationDrawer extends glass.GlassNavigationDrawer {
  const GlassmorphicKitNavigationDrawer({
    super.key,
    super.header,
    super.children = const <Widget>[],
    super.blur = glass.GlassConstants.defaultBlur,
    super.opacity = glass.GlassConstants.defaultOpacity,
    super.borderRadius,
    super.gradient,
    super.padding,
    super.width,
    super.backgroundColor,
    super.surfaceTintColor,
    super.shadowColor,
    super.elevation,
  });
}

class GlassmorphicKitProgressIndicator extends glass.GlassProgressIndicator {
  const GlassmorphicKitProgressIndicator({
    super.key,
    super.type = glass.GlassProgressType.linear,
    super.value,
    super.blur = glass.GlassConstants.defaultBlur,
    super.opacity = glass.GlassConstants.defaultOpacity,
    super.gradient,
  });
}

class GlassmorphicKitSlider extends glass.GlassSlider {
  const GlassmorphicKitSlider({
    super.key,
    required super.value,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min = 0.0,
    super.max = 1.0,
    super.divisions,
    super.label,
    super.activeColor,
    super.inactiveColor,
    super.activeTrackColor,
    super.inactiveTrackColor,
    super.activeThumbImage,
    super.inactiveThumbImage,
    super.thumbColor,
    super.trackColor,
    super.thumbIcon,
    super.dragStartBehavior = DragStartBehavior.start,
    super.mouseCursor,
    super.blur = glass.GlassConstants.defaultBlur,
    super.opacity = glass.GlassConstants.defaultOpacity,
    super.gradient,
    super.trackHeight = 4.0,
    super.borderRadius,
  });
}

class GlassmorphicKitTextField extends glass.GlassTextField {
  const GlassmorphicKitTextField({
    super.key,
    super.controller,
    super.hintText,
    super.prefixIcon,
    super.blur = glass.GlassConstants.defaultBlur,
    super.opacity = glass.GlassConstants.defaultOpacity,
    super.gradient,
  });
}
