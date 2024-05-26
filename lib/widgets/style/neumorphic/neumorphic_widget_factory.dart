import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_neumorphic/material_neumorphic.dart';

class NeumorphicWidgetFactory extends WidgetFactory {
  ThemeData buildThemeData(
      {Color seedColor = NeumorphicTheme.defaultSeedColor,
      Brightness brightness = Brightness.light}) {
    final colorScheme =
        ColorScheme.fromSeed(brightness: brightness, seedColor: seedColor);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[
        const NeumorphicTheme().fitWithColorSchema(colorScheme),
      ],
    );
  }

  @override
  Widget container({
    Key? key,
    Widget? child,
    Color? color,
    NeumorphicStyle? style,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Duration duration = NeumorphicTheme.defaultDuration,
    Curve curve = NeumorphicTheme.defaultCurve,
    bool drawSurfaceAboveChild = true,
  }) {
    return Neumorphic(
      key: key,
      color: color,
      style: style,
      margin: margin,
      padding: padding,
      duration: duration,
      curve: curve,
      drawSurfaceAboveChild: drawSurfaceAboveChild,
      child: child,
    );
  }

  @override
  Widget sizedBox({
    Key? key,
    required double width,
    required double height,
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
        width: width,
        height: height,
        child: Neumorphic(
          key: key,
          duration: duration,
          curve: curve,
          style: style,
          margin: margin,
          padding: padding,
          drawSurfaceAboveChild: drawSurfaceAboveChild,
          child: child,
        ));
  }

  Widget card({
    Widget? child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    Color backendColor = const Color(0xFF000000),
  }) {
    return NeumorphicBackground(
      padding: padding,
      margin: margin,
      backendColor: backendColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  Widget textFormField({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    FocusNode? focusNode,
    InputDecoration decoration = const InputDecoration(),
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    ToolbarOptions? toolbarOptions,
    bool? showCursor,
    String obscuringCharacter = '•',
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    MaxLengthEnforcement? maxLengthEnforcement,
    int? maxLines = 1,
    int minLines = 1,
    bool expands = false,
    int? maxLength,
    ValueChanged<String>? onChanged,
    GestureTapCallback? onTap,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool enableInteractiveSelection = true,
    TextSelectionControls? selectionControls,
    InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    AutovalidateMode? autovalidateMode,
    ScrollController? scrollController,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
  }) {
    return NeumorphicTextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: style,
      strutStyle: strutStyle,
      textDirection: textDirection,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      autofocus: autofocus,
      readOnly: readOnly,
      showCursor: showCursor,
      obscuringCharacter: obscuringCharacter = '•',
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLengthEnforcement: maxLengthEnforcement,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      onSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      selectionControls: selectionControls,
      buildCounter: buildCounter,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      scrollController: scrollController,
      restorationId: restorationId,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      mouseCursor: mouseCursor,
    );
  }

  Widget textField({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    InputDecoration? decoration = const InputDecoration(),
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    ToolbarOptions? toolbarOptions,
    bool? showCursor,
    String obscuringCharacter = '•',
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    MaxLengthEnforcement? maxLengthEnforcement,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    int? maxLength,
    ValueChanged<String>? onChanged,
    GestureTapCallback? onTap,
    VoidCallback? onEditingComplete,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    ScrollController? scrollController,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
  }) {
    return Neumorphic(
        child: TextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: style,
      strutStyle: strutStyle,
      textDirection: textDirection,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      autofocus: autofocus,
      readOnly: readOnly,
      toolbarOptions: toolbarOptions,
      showCursor: showCursor,
      obscuringCharacter: obscuringCharacter = '•',
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLengthEnforcement: maxLengthEnforcement,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      selectionControls: selectionControls,
      buildCounter: buildCounter,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      scrollController: scrollController,
      restorationId: restorationId,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      mouseCursor: mouseCursor,
    ));
  }

  @override
  Widget button({
    Key? key,
    Widget? child,
    void Function()? onPressed,
    void Function()? onLongPressed,
  }) {
    return NeumorphicButton(
      key: key,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      drawSurfaceAboveChild: true,
      pressed: onPressed != null,
      duration: NeumorphicTheme.defaultDuration,
      curve: NeumorphicTheme.defaultCurve,
      onPressed: onPressed,
      minDistance: 0,
      style: const NeumorphicStyle(),
      provideHapticFeedback: true,
      child: child,
    );
  }

  Widget radio({
    Widget? child,
    NeumorphicRadioStyle style = const NeumorphicRadioStyle(),
    dynamic value,
    Curve curve = NeumorphicTheme.defaultCurve,
    Duration duration = NeumorphicTheme.defaultDuration,
    EdgeInsets padding = EdgeInsets.zero,
    dynamic groupValue,
    void Function(dynamic)? onChanged,
    bool isEnabled = true,
  }) {
    return NeumorphicRadio(
      style: style,
      onChanged: onChanged,
      value: value,
      curve: curve,
      duration: duration,
      padding: padding,
      groupValue: groupValue,
      isEnabled: isEnabled,
      child: child,
    );
  }

  Widget checkbox({
    NeumorphicCheckboxStyle style = const NeumorphicCheckboxStyle(),
    required bool value,
    required void Function(dynamic) onChanged,
    Curve curve = NeumorphicTheme.defaultCurve,
    Duration duration = NeumorphicTheme.defaultDuration,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    EdgeInsets margin = const EdgeInsets.all(0),
    dynamic isEnabled = true,
  }) {
    return NeumorphicCheckbox(
        style: style,
        onChanged: onChanged,
        value: value,
        curve: curve,
        duration: duration,
        padding: padding,
        margin: margin,
        isEnabled: isEnabled);
  }

  @override
  Widget text(
    String data, {
    Key? key,
    TextStyle? style,
    Color color = Colors.white,
    double opacity = 0.5,
    double? fontSize,
    FontWeight fontWeight = FontWeight.bold,
    TextAlign textAlign = TextAlign.center,
    TextStyle? textStyle,
  }) {
    return NeumorphicText(
      data,
      key: key,
      duration: NeumorphicTheme.defaultDuration,
      style: NeumorphicStyle(color: color),
      curve: NeumorphicTheme.defaultCurve,
      textAlign: textAlign,
      textStyle: textStyle,
    );
  }

  @override
  Widget icon(
    IconData icon, {
    Key? key,
    double? size = 20,
    Color? color,
    double opacity = 0.5,
  }) {
    return NeumorphicIcon(
      icon,
      key: key,
      duration: NeumorphicTheme.defaultDuration,
      style: NeumorphicStyle(color: color),
      curve: NeumorphicTheme.defaultCurve,
      size: size ?? 20,
    );
  }

  Widget switchButton({
    NeumorphicSwitchStyle style = const NeumorphicSwitchStyle(),
    Key? key,
    Curve curve = NeumorphicTheme.defaultCurve,
    Duration duration = NeumorphicTheme.defaultDuration,
    bool value = false,
    void Function(bool)? onChanged,
    double height = 40,
    bool isEnabled = true,
  }) {
    return NeumorphicSwitch(
        key: key,
        duration: duration,
        style: style,
        curve: curve,
        value: value,
        onChanged: onChanged,
        height: height,
        isEnabled: isEnabled);
  }

  Widget toggle({
    NeumorphicToggleStyle? style = const NeumorphicToggleStyle(),
    Key? key,
    required List<ToggleElement> children,
    required Widget thumb,
    EdgeInsets padding = const EdgeInsets.all(2),
    Duration duration = const Duration(milliseconds: 200),
    int selectedIndex = 0,
    Curve alphaAnimationCurve = Curves.linear,
    Curve movingCurve = Curves.linear,
    dynamic Function(int)? onAnimationChangedFinished,
    void Function(int)? onChanged,
    double height = 40,
    double? width,
    bool isEnabled = true,
    bool displayForegroundOnlyIfSelected = true,
  }) {
    return NeumorphicToggle(
      key: key,
      duration: duration,
      style: style,
      thumb: thumb,
      padding: padding,
      onChanged: onChanged,
      height: height,
      width: width,
      isEnabled: isEnabled,
      selectedIndex: selectedIndex,
      alphaAnimationCurve: alphaAnimationCurve,
      movingCurve: movingCurve,
      onAnimationChangedFinished: onAnimationChangedFinished,
      displayForegroundOnlyIfSelected: displayForegroundOnlyIfSelected,
      children: children,
    );
  }

  Widget slider({
    Key? key,
    SliderStyle style = const SliderStyle(),
    double min = 0,
    double value = 0,
    double max = 10,
    double height = 15,
    void Function(double)? onChanged,
    void Function(double)? onChangeStart,
    void Function(double)? onChangeEnd,
    Widget? thumb,
    double? sliderHeight,
  }) {
    return NeumorphicSlider(
      key: key,
      style: style,
      min: min,
      value: value,
      max: max,
      height: height,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      thumb: thumb,
      sliderHeight: sliderHeight,
    );
  }

  Widget progress({
    Key? key,
    double? percent,
    double height = 10,
    Duration duration = NeumorphicTheme.defaultDuration,
    ProgressStyle style = const ProgressStyle(),
    Curve curve = Curves.easeOutCubic,
  }) {
    return NeumorphicProgress(
      key: key,
      duration: duration,
      style: style,
      curve: curve,
      percent: percent,
      height: height,
    );
  }

  Widget progressIndeterminate({
    Key? key,
    double height = 10,
    ProgressStyle style = const ProgressStyle(),
    Duration duration = const Duration(seconds: 3),
    bool reverse = false,
    Curve curve = Curves.easeInOut,
  }) {
    return NeumorphicProgressIndeterminate(
      key: key,
      duration: duration,
      style: style,
      curve: curve,
      reverse: reverse,
      height: height,
    );
  }

  @override
  PreferredSizeWidget appBar({
    Key? key,
    Widget? title,
    EdgeInsets? buttonPadding,
    NeumorphicStyle? buttonStyle,
    IconThemeData? iconTheme,
    Color? color,
    List<Widget>? actions,
    TextStyle? textStyle,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool? centerTitle,
    double titleSpacing = NavigationToolbar.kMiddleSpacing,
    double actionSpacing = NeumorphicAppBar.defaultSpacing,
    double padding = 16,
  }) {
    return NeumorphicAppBar(
      key: key,
      title: title,
      buttonPadding: buttonPadding,
      buttonStyle: buttonStyle,
      iconTheme: iconTheme,
      color: color,
      actions: actions,
      textStyle: textStyle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      actionSpacing: actionSpacing,
      padding: padding = 16,
    );
  }

  @override
  Widget bottomNavigationBar({
    Key? key,
    required List<BottomNavigationBarItem> items,
    int currentIndex = 0,
    Function(int p1)? onTap,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    double? selectedColorOpacity,
  }) {
    return Neumorphic(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuint,
        child: BottomNavigationBar(
          items: items,
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
        ));
  }

  @override
  Widget listTile(
      {Key? key,
      Widget? leading,
      Widget? title,
      Widget? subtitle,
      Widget? trailing,
      void Function()? onTap}) {
    return Neumorphic(
        child: ListTile(
      key: key,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    ));
  }
}

final NeumorphicWidgetFactory neumorphicWidgetFactory =
    NeumorphicWidgetFactory();
