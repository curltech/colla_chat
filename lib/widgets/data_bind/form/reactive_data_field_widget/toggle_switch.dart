import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:toggle_switch/toggle_switch.dart';

class ReactiveToggleSwitch<T> extends ReactiveFormField<T, T> {
  ReactiveToggleSwitch({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    List<Color>? borderColor,
    Color dividerColor = Colors.white30,
    List<Color>? activeBgColor,
    Color? activeFgColor,
    Color? inactiveBgColor,
    Color? inactiveFgColor,
    int? totalSwitches,
    List<List<Color>?>? activeBgColors,
    List<TextStyle?>? customTextStyles,
    List<Icon?>? customIcons,
    List<double>? customWidths,
    List<double>? customHeights,
    double minWidth = 72,
    double minHeight = 40,
    double cornerRadius = 8.0,
    double fontSize = 13,
    double iconSize = 17,
    double dividerMargin = 8.0,
    double? borderWidth,
    bool changeOnTap = true,
    bool animate = false,
    int animationDuration = 800,
    bool radiusStyle = false,
    bool textDirectionRTL = false,
    Curve curve = Curves.easeIn,
    bool doubleTapDisable = false,
    bool isVertical = false,
    List<Border?>? activeBorders,
    bool centerText = false,
    bool multiLineText = false,
    ReactiveFormFieldCallback<T>? onToggle,
    Future<bool> Function(T?)? cancelToggle,
    List<bool>? states,
    List<Widget>? customWidgets,
  }) : super(
    builder: (field) {
      T? value = field.value;
      List<String> labels = [];
      List<IconData> icons = [];
      int? initialLabelIndex;
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        if (option.icon != null) {
          icons.add(option.icon!);
        } else {
          labels.add(option.label);
        }
        if (value == option.value) {
          initialLabelIndex = i;
        }
      }
      return ToggleSwitch(
        borderColor: borderColor,
        dividerColor: dividerColor,
        activeBgColor: activeBgColor,
        activeFgColor: activeFgColor,
        inactiveBgColor: inactiveBgColor,
        inactiveFgColor: inactiveFgColor,
        labels: labels,
        totalSwitches: totalSwitches,
        icons: icons,
        activeBgColors: activeBgColors,
        customTextStyles: customTextStyles,
        customIcons: customIcons,
        customWidths: customWidths,
        customHeights: customHeights,
        minWidth: minWidth,
        minHeight: minHeight,
        cornerRadius: cornerRadius,
        fontSize: fontSize,
        iconSize: iconSize,
        dividerMargin: dividerMargin,
        borderWidth: borderWidth,
        onToggle: (int? index) {
          if (index != null) {
            var option = options[index];
            field.didChange.call(option.value);
            onToggle?.call(field.control);
          }
        },
        changeOnTap: changeOnTap,
        animate: animate,
        animationDuration: animationDuration,
        radiusStyle: radiusStyle,
        textDirectionRTL: textDirectionRTL,
        curve: curve,
        initialLabelIndex: initialLabelIndex,
        doubleTapDisable: doubleTapDisable,
        isVertical: isVertical,
        activeBorders: activeBorders,
        states: states,
        cancelToggle: (int? index) {
          if (index != null) {
            var option = options[index];
            cancelToggle?.call(option.value);

            return Future.value(true);
          }
          return Future.value(false);
        },
        centerText: centerText,
        multiLineText: multiLineText,
        customWidgets: customWidgets,
      );
    },
  );
}