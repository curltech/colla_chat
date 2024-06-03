import 'dart:ui';

import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_neumorphic/material_neumorphic.dart';

class NeumorphicWidgetFactory extends WidgetFactory {
  ///创建neumorphic样式
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
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Widget? child,
    Clip clipBehavior = Clip.none,
  }) {
    return Neumorphic(
      key: key,
      color: color,
      style: NeumorphicStyle(color: color),
      margin: EdgeInsets.symmetric(
          vertical: margin?.vertical ?? 0.0,
          horizontal: margin?.horizontal ?? 0.0),
      padding: EdgeInsets.symmetric(
          vertical: margin?.vertical ?? 0.0,
          horizontal: margin?.horizontal ?? 0.0),
      duration: NeumorphicTheme.defaultDuration,
      curve: NeumorphicTheme.defaultCurve,
      drawSurfaceAboveChild: true,
      child: child,
    );
  }

  @override
  Widget sizedBox({
    Key? key,
    double? width,
    double? height,
    Widget? child,
  }) {
    return SizedBox(
        width: width,
        height: height,
        child: Neumorphic(
          key: key,
          duration: NeumorphicTheme.defaultDuration,
          curve: NeumorphicTheme.defaultCurve,
          drawSurfaceAboveChild: true,
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
    NeumorphicStyle? neumorphicStyle,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? color,
    double? depth,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    TextEditingController? controller,
    FocusNode? focusNode,
    UndoHistoryController? undoController,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    TextDirection? textDirection,
    bool readOnly = false,
    ToolbarOptions? toolbarOptions,
    bool? showCursor,
    bool autofocus = false,
    String obscuringCharacter = '•',
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    void Function(String)? onChanged,
    void Function()? onEditingComplete,
    void Function(String)? onSubmitted,
    void Function(String, Map<String, dynamic>)? onAppPrivateCommand,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    bool? cursorOpacityAnimates,
    Color? cursorColor,
    BoxHeightStyle selectionHeightStyle = BoxHeightStyle.tight,
    BoxWidthStyle selectionWidthStyle = BoxWidthStyle.tight,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    void Function()? onTap,
    void Function(PointerDownEvent)? onTapOutside,
    MouseCursor? mouseCursor,
    Widget? Function(BuildContext,
            {required int currentLength,
            required bool isFocused,
            required int? maxLength})?
        buildCounter,
    ScrollController? scrollController,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints = const <String>[],
    ContentInsertionConfiguration? contentInsertionConfiguration,
    Clip clipBehavior = Clip.hardEdge,
    String? restorationId,
    bool scribbleEnabled = true,
    bool enableIMEPersonalizedLearning = true,
    Widget Function(BuildContext, EditableTextState)? contextMenuBuilder,
    bool canRequestFocus = true,
    SpellCheckConfiguration? spellCheckConfiguration,
    TextMagnifierConfiguration? magnifierConfiguration,
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
      onSubmitted: onSubmitted,
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
    required void Function()? onPressed,
    void Function()? onLongPress,
    void Function(bool)? onHover,
    void Function(bool)? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    Clip? clipBehavior,
    WidgetStatesController? statesController,
    bool? isSemanticButton = true,
    required Widget child,
    IconAlignment iconAlignment = IconAlignment.start,
  }) {
    return NeumorphicButton(
      key: key,
      drawSurfaceAboveChild: true,
      duration: NeumorphicTheme.defaultDuration,
      curve: NeumorphicTheme.defaultCurve,
      onPressed: onPressed,
      provideHapticFeedback: true,
      child: child,
    );
  }

  Widget radio({
    Widget? child,
    NeumorphicRadioStyle style = const NeumorphicRadioStyle(),
    Object? value,
    Curve curve = NeumorphicTheme.defaultCurve,
    Duration duration = NeumorphicTheme.defaultDuration,
    EdgeInsets padding = EdgeInsets.zero,
    Object? groupValue,
    void Function(Object?)? onChanged,
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
    required void Function(bool) onChanged,
    Curve curve = NeumorphicTheme.defaultCurve,
    Duration duration = NeumorphicTheme.defaultDuration,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    EdgeInsets margin = const EdgeInsets.all(0),
    bool isEnabled = true,
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
    TextAlign? textAlign,
    TextStyle? textStyle,
    bool wrapWords = true,
    TextOverflow? overflow,
    Widget? overflowReplacement,
    double? textScaleFactor,
    int? maxLines,
  }) {
    return NeumorphicText(
      data,
      key: key,
      duration: NeumorphicTheme.defaultDuration,
      style: NeumorphicStyle(color: textStyle?.color),
      curve: NeumorphicTheme.defaultCurve,
      textAlign: textAlign,
      textStyle: textStyle,
    );
  }

  @override
  Widget icon(
    IconData icon, {
    Key? key,
    double? size,
    double? fill,
    double? weight,
    double? grade,
    double? opticalSize,
    Color? color,
    List<Shadow>? shadows,
    String? semanticLabel,
    TextDirection? textDirection,
    bool? applyTextScaling,
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
    Duration duration = const Duration(milliseconds: 200),
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
    EdgeInsets padding = const EdgeInsets.all(4),
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
    Duration duration = const Duration(milliseconds: 300),
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
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Widget? title,
    List<Widget>? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
    double? elevation,
    double? scrolledUnderElevation,
    bool Function(ScrollNotification) notificationPredicate =
        defaultScrollNotificationPredicate,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Color? backgroundColor,
    Color? foregroundColor,
    IconThemeData? iconTheme,
    IconThemeData? actionsIconTheme,
    bool primary = true,
    bool? centerTitle,
    bool excludeHeaderSemantics = false,
    double? titleSpacing,
    double toolbarOpacity = 1.0,
    double bottomOpacity = 1.0,
    double? toolbarHeight,
    double? leadingWidth,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
    bool forceMaterialTransparency = false,
    Clip? clipBehavior,
  }) {
    return NeumorphicAppBar(
      key: key,
      title: title,
      iconTheme: iconTheme,
      color: backgroundColor,
      actions: actions,
      textStyle: titleTextStyle,
      leading: leading,
      automaticallyImplyLeading: true,
      centerTitle: centerTitle,
      titleSpacing: NavigationToolbar.kMiddleSpacing,
      actionSpacing: NeumorphicAppBar.defaultSpacing,
      padding: 16,
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
  Widget listTile({
    Key? key,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    bool isThreeLine = false,
    bool? dense,
    VisualDensity? visualDensity,
    ShapeBorder? shape,
    ListTileStyle? style,
    Color? selectedColor,
    Color? iconColor,
    Color? textColor,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? leadingAndTrailingTextStyle,
    EdgeInsetsGeometry? contentPadding,
    bool enabled = true,
    void Function()? onTap,
    void Function()? onLongPress,
    void Function(bool)? onFocusChange,
    MouseCursor? mouseCursor,
    bool selected = false,
    Color? focusColor,
    Color? hoverColor,
    Color? splashColor,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    double? horizontalTitleGap,
    double? minVerticalPadding,
    double? minLeadingWidth,
    double? minTileHeight,
    ListTileTitleAlignment? titleAlignment,
  }) {
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
