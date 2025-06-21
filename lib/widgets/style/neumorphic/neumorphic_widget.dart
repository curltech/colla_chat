import 'dart:ui';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_neumorphic/material_neumorphic.dart';

buildThemeData() {
  ThemeData themeData = myself.themeData.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const NeumorphicTheme().fitWithColorSchema(myself.colorScheme),
    ],
  );
  ThemeData darkThemeData = myself.darkThemeData.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const NeumorphicTheme().fitWithColorSchema(myself.darkColorScheme),
    ],
  );
  myself.setThemeData(themeData: themeData, darkThemeData: darkThemeData);
}

extension NeumorphicWidget<T extends Widget> on T {
  Widget asNeumorphicStyle({
    Key? key,
    double? height,
    double? width,
    Widget? child,
    Color? color,
    NeumorphicStyle? style,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Duration duration = NeumorphicTheme.defaultDuration,
    Curve curve = NeumorphicTheme.defaultCurve,
    bool drawSurfaceAboveChild = true,
  }) {
    return SizedBox(
        height: height,
        width: width,
        child: Neumorphic(
          key: key,
          color: color,
          style: style,
          margin: margin,
          padding: padding,
          duration: duration,
          curve: curve,
          drawSurfaceAboveChild: drawSurfaceAboveChild,
          child: this,
        ));
  }
}

class NeumorphicStyleContainer extends Neumorphic {
  final double? height;
  final double? width;

  NeumorphicStyleContainer({
    super.key,
    this.height,
    this.width,
    super.child,
    super.color,
    super.style,
    super.margin,
    super.padding,
    super.duration = NeumorphicTheme.defaultDuration,
    super.curve = NeumorphicTheme.defaultCurve,
    super.drawSurfaceAboveChild = true,
  });

  @override
  Widget build(BuildContext context) {
    return child!.asNeumorphicStyle(
        key: key,
        height: height,
        width: width,
        color: color,
        style: style,
        margin: margin,
        padding: padding,
        duration: duration,
        curve: curve,
        drawSurfaceAboveChild: drawSurfaceAboveChild);
  }
}

class NeumorphicStyleCard extends NeumorphicBackground {
  const NeumorphicStyleCard({
    super.child,
    super.padding,
    super.margin,
    super.borderRadius,
    super.backendColor = const Color(0xFF000000),
  });
}

class NeumorphicStyleAppBar extends NeumorphicAppBar {
  NeumorphicStyleAppBar({
    super.key,
    super.title,
    super.buttonPadding,
    super.buttonStyle,
    super.iconTheme,
    super.color,
    super.actions,
    super.textStyle,
    super.leading,
    super.automaticallyImplyLeading = true,
    super.centerTitle,
    super.titleSpacing = NavigationToolbar.kMiddleSpacing,
    super.actionSpacing = 4.0,
    super.padding = 16,
    super.depth,
  });
}

class NeumorphicStyleText extends NeumorphicText {
  NeumorphicStyleText(
    super.text, {
    super.key,
    super.duration = NeumorphicTheme.defaultDuration,
    super.curve = NeumorphicTheme.defaultCurve,
    super.style,
    super.textAlign,
    super.textStyle,
  });
}

class NeumorphicStyleTextField extends NeumorphicTextField {
  NeumorphicStyleTextField({
    super.key,
    super.neumorphicStyle,
    super.margin,
    super.padding,
    super.color,
    super.depth,
    super.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    super.controller,
    super.focusNode,
    super.undoController,
    super.decoration,
    super.keyboardType,
    super.textInputAction,
    super.textCapitalization = TextCapitalization.none,
    super.style,
    super.strutStyle,
    super.textAlign = TextAlign.start,
    super.textAlignVertical,
    super.textDirection,
    super.readOnly = false,
    super.toolbarOptions,
    super.showCursor,
    super.autofocus = false,
    super.obscuringCharacter = '•',
    super.obscureText = false,
    super.autocorrect = true,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions = true,
    super.maxLines = 1,
    super.minLines,
    super.expands = false,
    super.maxLength,
    super.maxLengthEnforcement,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.inputFormatters,
    super.enabled,
    super.cursorWidth = 2.0,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorOpacityAnimates,
    super.cursorColor,
    super.selectionHeightStyle = BoxHeightStyle.tight,
    super.selectionWidthStyle = BoxWidthStyle.tight,
    super.keyboardAppearance,
    super.scrollPadding = const EdgeInsets.all(20.0),
    super.dragStartBehavior = DragStartBehavior.start,
    super.enableInteractiveSelection,
    super.selectionControls,
    super.onTap,
    super.onTapOutside,
    super.mouseCursor,
    super.buildCounter,
    super.scrollController,
    super.scrollPhysics,
    super.autofillHints = const <String>[],
    super.contentInsertionConfiguration,
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.scribbleEnabled = true,
    super.enableIMEPersonalizedLearning = true,
    super.contextMenuBuilder,
    super.canRequestFocus = true,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
  });
}

class NeumorphicStyleButton extends NeumorphicButton {
  NeumorphicStyleButton({
    super.key,
    super.padding,
    super.margin,
    super.child,
    super.tooltip,
    super.drawSurfaceAboveChild = true,
    super.pressed, //true/false if you want to change the state of the button
    super.duration = NeumorphicTheme.defaultDuration,
    super.curve = NeumorphicTheme.defaultCurve,
    super.onPressed,
    super.minDistance = 0,
    super.style,
    super.provideHapticFeedback = true,
  });
}

class NeumorphicStyleRadio extends NeumorphicRadio {
  NeumorphicStyleRadio({
    super.child,
    super.style = const NeumorphicRadioStyle(),
    super.value,
    super.curve = NeumorphicTheme.defaultCurve,
    super.duration = NeumorphicTheme.defaultDuration,
    super.padding = EdgeInsets.zero,
    super.groupValue,
    super.onChanged,
    super.isEnabled = true,
  });
}

class NeumorphicStyleCheckbox extends NeumorphicCheckbox {
  NeumorphicStyleCheckbox({
    super.style = const NeumorphicCheckboxStyle(),
    required super.value,
    required super.onChanged,
    super.curve = NeumorphicTheme.defaultCurve,
    super.duration = NeumorphicTheme.defaultDuration,
    super.padding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    super.margin = const EdgeInsets.all(0),
    super.isEnabled = true,
  });
}

class NeumorphicStyleIcon extends NeumorphicIcon {
  NeumorphicStyleIcon(
    super.icon, {
    super.key,
    super.duration = NeumorphicTheme.defaultDuration,
    super.curve = NeumorphicTheme.defaultCurve,
    super.style,
    super.size = 20,
  });
}

class NeumorphicStyleSwitch extends NeumorphicSwitch {
  const NeumorphicStyleSwitch({
    super.key,
    super.style = const NeumorphicSwitchStyle(),
    super.curve = NeumorphicTheme.defaultCurve,
    super.duration = const Duration(milliseconds: 200),
    super.value = false,
    super.onChanged,
    super.height = 40,
    super.isEnabled = true,
  });
}

class NeumorphicStyleToggle extends NeumorphicToggle {
  const NeumorphicStyleToggle({
    super.key,
    super.style = const NeumorphicToggleStyle(),
    required super.children,
    required super.thumb,
    super.padding = const EdgeInsets.all(4),
    super.duration = const Duration(milliseconds: 200),
    super.selectedIndex = 0,
    super.alphaAnimationCurve = Curves.linear,
    super.movingCurve = Curves.linear,
    super.onAnimationChangedFinished,
    super.onChanged,
    super.height = 40,
    super.width,
    super.isEnabled = true,
    super.displayForegroundOnlyIfSelected = true,
  });
}

class NeumorphicStyleSlider extends NeumorphicSlider {
  NeumorphicStyleSlider({
    super.key,
    super.style = const SliderStyle(),
    super.min = 0,
    super.value = 0,
    super.max = 10,
    super.height = 15,
    super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.thumb,
    super.sliderHeight,
  });
}

class NeumorphicStyleProgress extends NeumorphicProgress {
  const NeumorphicStyleProgress(
      {super.key,
      double? percent,
      super.height = 10,
      super.duration = const Duration(milliseconds: 300),
      super.style = const ProgressStyle(),
      super.curve = Curves.easeOutCubic});
}

class NeumorphicStyleProgressIndeterminate
    extends NeumorphicProgressIndeterminate {
  const NeumorphicStyleProgressIndeterminate({
    super.key,
    super.height = 10,
    super.style = const ProgressStyle(),
    super.duration = const Duration(seconds: 3),
    super.reverse = false,
    super.curve = Curves.easeInOut,
  });
}

class NeumorphicStyleDropdownButton extends NeumorphicDropdownButton {
  NeumorphicStyleDropdownButton({
    super.neumorphicStyle,
    super.margin,
    super.padding,
    super.color,
    super.depth,
    super.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    super.key,
    required super.items,
    super.selectedItemBuilder,
    super.value,
    super.hint,
    super.disabledHint,
    required super.onChanged,
    super.onTap,
    super.elevation = 8,
    super.style,
    super.underline,
    super.icon,
    super.iconDisabledColor,
    super.iconEnabledColor,
    super.iconSize = 24.0,
    super.isDense = true,
    super.isExpanded = false,
    super.itemHeight,
    super.focusColor,
    super.focusNode,
    super.autofocus = false,
    super.dropdownColor,
    super.menuMaxHeight,
    super.enableFeedback,
    super.alignment = AlignmentDirectional.centerStart,
  });
}
