import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/widgets/common/nil.dart';
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
          vertical: padding?.vertical ?? 0.0,
          horizontal: padding?.horizontal ?? 0.0),
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

  @override
  Widget card({
    Key? key,
    Color? color,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    ShapeBorder? shape,
    bool borderOnForeground = true,
    EdgeInsetsGeometry? margin,
    Clip? clipBehavior,
    Widget? child,
    bool semanticContainer = true,
  }) {
    return NeumorphicBackground(
      margin: margin?.resolve(null),
      backendColor: color ?? const Color(0xFF000000),
      child: child,
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
  Widget text(
    String data, {
    Key? key,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    TextScaler? textScaler,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    return NeumorphicText(
      data,
      key: key,
      duration: NeumorphicTheme.defaultDuration,
      style: NeumorphicStyle(color: style?.color),
      curve: NeumorphicTheme.defaultCurve,
      textAlign: textAlign,
      textStyle: style,
    );
  }

  ///自适应文本
  @override
  Widget commonAutoSizeText(
    String data, {
    Key? key,
    Key? textKey,
    TextStyle? style,
    StrutStyle? strutStyle,
    double minFontSize = AppFontSize.minFontSize,
    double maxFontSize = AppFontSize.maxFontSize,
    double stepGranularity = 1,
    List<double>? presetFontSizes,
    AutoSizeGroup? group,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    bool wrapWords = true,
    TextOverflow? overflow,
    Widget? overflowReplacement,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
  }) {
    return NeumorphicText(
      data,
      key: key,
      duration: NeumorphicTheme.defaultDuration,
      style: NeumorphicStyle(color: style?.color),
      curve: NeumorphicTheme.defaultCurve,
      textAlign: textAlign,
      textStyle: style,
    );
  }

  ///输入框
  @override
  Widget textField({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    UndoHistoryController? undoController,
    InputDecoration? decoration = const InputDecoration(),
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
    WidgetStatesController? statesController,
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
    bool? ignorePointers,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    bool? cursorOpacityAnimates,
    Color? cursorColor,
    Color? cursorErrorColor,
    BoxHeightStyle selectionHeightStyle = BoxHeightStyle.tight,
    BoxWidthStyle selectionWidthStyle = BoxWidthStyle.tight,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    void Function()? onTap,
    bool onTapAlwaysCalled = false,
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

  @override
  Widget textFormField({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
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
    void Function(String)? onChanged,
    void Function()? onTap,
    bool onTapAlwaysCalled = false,
    void Function(PointerDownEvent)? onTapOutside,
    void Function()? onEditingComplete,
    void Function(String)? onFieldSubmitted,
    void Function(String?)? onSaved,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    bool? ignorePointers,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Color? cursorErrorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool? enableInteractiveSelection,
    TextSelectionControls? selectionControls,
    Widget? Function(BuildContext,
            {required int currentLength,
            required bool isFocused,
            required int? maxLength})?
        buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    AutovalidateMode? autovalidateMode,
    ScrollController? scrollController,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
    Widget Function(BuildContext, EditableTextState)? contextMenuBuilder,
    SpellCheckConfiguration? spellCheckConfiguration,
    TextMagnifierConfiguration? magnifierConfiguration,
    UndoHistoryController? undoController,
    void Function(String, Map<String, dynamic>)? onAppPrivateCommand,
    bool? cursorOpacityAnimates,
    BoxHeightStyle selectionHeightStyle = BoxHeightStyle.tight,
    BoxWidthStyle selectionWidthStyle = BoxWidthStyle.tight,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ContentInsertionConfiguration? contentInsertionConfiguration,
    WidgetStatesController? statesController,
    Clip clipBehavior = Clip.hardEdge,
    bool scribbleEnabled = true,
    bool canRequestFocus = true,
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

  @override
  Widget radio({
    Key? key,
    required dynamic value,
    required dynamic groupValue,
    required void Function(dynamic)? onChanged,
    MouseCursor? mouseCursor,
    bool toggleable = false,
    Color? activeColor,
    WidgetStateProperty<Color?>? fillColor,
    Color? focusColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return NeumorphicRadio(
      style: NeumorphicRadioStyle(selectedColor: activeColor),
      onChanged: onChanged,
      value: value,
      groupValue: groupValue,
    );
  }

  @override
  Widget checkbox({
    Key? key,
    required bool? value,
    bool tristate = false,
    required void Function(bool?)? onChanged,
    MouseCursor? mouseCursor,
    Color? activeColor,
    WidgetStateProperty<Color?>? fillColor,
    Color? checkColor,
    Color? focusColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
    OutlinedBorder? shape,
    BorderSide? side,
    bool isError = false,
    String? semanticLabel,
  }) {
    return NeumorphicCheckbox(
      style: NeumorphicCheckboxStyle(
        selectedColor: checkColor,
      ),
      onChanged: (value) {
        onChanged!(value);
      },
      value: value ?? false,
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

  @override
  Widget switchButton({
    Key? key,
    required bool value,
    required void Function(bool)? onChanged,
    Color? activeColor,
    Color? activeTrackColor,
    Color? inactiveThumbColor,
    Color? inactiveTrackColor,
    ImageProvider<Object>? activeThumbImage,
    void Function(Object, StackTrace?)? onActiveThumbImageError,
    ImageProvider<Object>? inactiveThumbImage,
    void Function(Object, StackTrace?)? onInactiveThumbImageError,
    WidgetStateProperty<Color?>? thumbColor,
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? trackOutlineColor,
    WidgetStateProperty<double?>? trackOutlineWidth,
    WidgetStateProperty<Icon?>? thumbIcon,
    MaterialTapTargetSize? materialTapTargetSize,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    MouseCursor? mouseCursor,
    Color? focusColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    FocusNode? focusNode,
    void Function(bool)? onFocusChange,
    bool autofocus = false,
  }) {
    return NeumorphicSwitch(
      key: key,
      style: NeumorphicSwitchStyle(
        activeTrackColor: activeTrackColor,
        inactiveTrackColor: inactiveTrackColor,
        inactiveThumbColor: inactiveThumbColor,
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget toggle({
    Key? key,
    required List children,
    required List isSelected,
    void Function(int)? onPressed,
    MouseCursor? mouseCursor,
    MaterialTapTargetSize? tapTargetSize,
    TextStyle? textStyle,
    BoxConstraints? constraints,
    Color? color,
    Color? selectedColor,
    Color? disabledColor,
    Color? fillColor,
    Color? focusColor,
    Color? highlightColor,
    Color? hoverColor,
    Color? splashColor,
    List? focusNodes,
    bool renderBorder = true,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? disabledBorderColor,
    BorderRadius? borderRadius,
    double? borderWidth,
    Axis direction = Axis.horizontal,
    VerticalDirection verticalDirection = VerticalDirection.down,
  }) {
    return NeumorphicToggle(
      key: key,
      style: const NeumorphicToggleStyle(),
      thumb: nil,
      children: const [],
    );
  }

  @override
  Widget slider({
    Key? key,
    required double value,
    required void Function(double)? onChanged,
    void Function(double)? onChangeStart,
    void Function(double)? onChangeEnd,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    String? label,
    Color? activeColor,
    Color? inactiveColor,
    Color? thumbColor,
    MouseCursor? mouseCursor,
    String Function(double)? semanticFormatterCallback,
    FocusNode? focusNode,
    bool autofocus = false,
    SliderInteraction? allowedInteraction,
  }) {
    return NeumorphicSlider(
      key: key,
      style: SliderStyle(accent: activeColor, variant: inactiveColor),
      min: min,
      value: value,
      max: max,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );
  }

  @override
  Widget progress({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? color,
    Animation<Color?>? valueColor,
    double? minHeight,
    String? semanticsLabel,
    String? semanticsValue,
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
  }) {
    return NeumorphicProgress(
      key: key,
      style: ProgressStyle(
          accent: backgroundColor,
          variant: color,
          borderRadius: borderRadius.resolve(null)),
      height: minHeight ?? 10,
    );
  }

  @override
  Widget progressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? color,
    Animation<Color?>? valueColor,
    double? minHeight,
    String? semanticsLabel,
    String? semanticsValue,
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
  }) {
    return NeumorphicProgressIndeterminate(
      key: key,
      style: ProgressStyle(
          accent: backgroundColor,
          variant: color,
          borderRadius: borderRadius.resolve(null)),
      height: minHeight ?? 10,
    );
  }

  ///下拉按钮
  @override
  Widget dropdownButton({
    Key? key,
    required List<DropdownMenuItem<double>>? items,
    List<Widget> Function(BuildContext)? selectedItemBuilder,
    double? value,
    Widget? hint,
    Widget? disabledHint,
    required void Function(double?)? onChanged,
    void Function()? onTap,
    int elevation = 8,
    TextStyle? style,
    Widget? underline,
    Widget? icon,
    Color? iconDisabledColor,
    Color? iconEnabledColor,
    double iconSize = 24.0,
    bool isDense = false,
    bool isExpanded = false,
    double? itemHeight = kMinInteractiveDimension,
    Color? focusColor,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? dropdownColor,
    double? menuMaxHeight,
    bool? enableFeedback,
    AlignmentGeometry alignment = AlignmentDirectional.centerStart,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return NeumorphicDropdownButton(
        neumorphicStyle: NeumorphicStyle(color: iconEnabledColor),
        borderRadius:
            borderRadius ?? const BorderRadius.all(Radius.circular(8.0)),
        icon: icon,
        iconDisabledColor: iconDisabledColor,
        iconEnabledColor: iconEnabledColor,
        iconSize: iconSize,
        isExpanded: isExpanded,
        isDense: isDense,
        focusNode: focusNode,
        focusColor: focusColor,
        dropdownColor: dropdownColor,
        disabledHint: disabledHint,
        value: value,
        elevation: elevation,
        autofocus: autofocus,
        menuMaxHeight: menuMaxHeight,
        enableFeedback: enableFeedback,
        padding: padding?.resolve(null),
        alignment: alignment,
        itemHeight: itemHeight,
        underline: underline,
        hint: hint,
        items: items,
        onChanged: onChanged,
        onTap: onTap,
        selectedItemBuilder: selectedItemBuilder);
  }
}

final NeumorphicWidgetFactory neumorphicWidgetFactory =
    NeumorphicWidgetFactory();
