import 'dart:ui';

import 'package:badges/badges.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../routers/routes.dart';
import '../platform_widget_factory.dart';

///Material的部件工厂，这是缺省的部件工厂，其他样式的部件工厂没有类似的部件就使用这里的部件
///如果其他样式有新的部件可以在这里添加自定义的部件进行支持
///分成容器，输入和展示的小部件，按钮，对话框，应用等及大类
///这里不包含布局组件，因为可以通用在任何样式中，可以不采用工厂的方式
class MaterialWidgetFactory extends WidgetFactory {
  ///可变容器
  @override
  Widget buildContainer({
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
    return Container(
      key: key,
      margin: margin,
      padding: padding,
      child: child,
    );
  }

  ///指定大小的容器
  @override
  Widget buildSizedBox({
    Key? key,
    double? width,
    double? height,
    Widget? child,
  }) {
    return SizedBox(
      key: key,
      child: child,
    );
  }

  Widget buildCard({
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
    return Card(
      margin: margin,
      child: child,
    );
  }

  ExpansionPanel buildExpansionPanel({
    required Widget Function(BuildContext, bool) headerBuilder,
    required Widget body,
    bool isExpanded = false,
    bool canTapOnHeader = false,
    Color? backgroundColor,
  }) {
    return ExpansionPanel(
      body: body,
      headerBuilder: headerBuilder,
    );
  }

  Widget buildPageView({
    Key? key,
    Axis scrollDirection = Axis.horizontal,
    bool reverse = false,
    PageController? controller,
    ScrollPhysics? physics,
    bool pageSnapping = true,
    void Function(int)? onPageChanged,
    List children = const [],
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool allowImplicitScrolling = false,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    ScrollBehavior? scrollBehavior,
    bool padEnds = true,
  }) {
    return PageView();
  }

  Widget buildDataTable2({
    Key? key,
    required List<DataColumn> columns,
    int? sortColumnIndex,
    bool sortAscending = true,
    void Function(bool?)? onSelectAll,
    Decoration? decoration,
    MaterialStateProperty? dataRowColor,
    double? dataRowHeight,
    TextStyle? dataTextStyle,
    MaterialStateProperty? headingRowColor,
    Color? fixedColumnsColor,
    Color? fixedCornerColor,
    double? headingRowHeight,
    TextStyle? headingTextStyle,
    double? horizontalMargin,
    double? checkboxHorizontalMargin,
    double? bottomMargin,
    double? columnSpacing,
    bool showCheckboxColumn = true,
    bool showBottomBorder = false,
    double? dividerThickness,
    double? minWidth,
    ScrollController? scrollController,
    Widget? empty,
    TableBorder? border,
    double smRatio = 0.67,
    int fixedTopRows = 1,
    int fixedLeftColumns = 0,
    double lmRatio = 1.2,
    required List<DataRow> rows,
  }) {
    return DataTable2(
      columns: columns,
      rows: rows,
    );
  }

  Widget buildTabBar({
    Key? key,
    required List<Widget> tabs,
    TabController? controller,
    bool isScrollable = false,
    EdgeInsetsGeometry? padding,
    Color? indicatorColor,
    bool automaticIndicatorColorAdjustment = true,
    double indicatorWeight = 2.0,
    EdgeInsetsGeometry indicatorPadding = EdgeInsets.zero,
    Decoration? indicator,
    TabBarIndicatorSize? indicatorSize,
    Color? labelColor,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? labelPadding,
    Color? unselectedLabelColor,
    TextStyle? unselectedLabelStyle,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    MaterialStateProperty? overlayColor,
    MouseCursor? mouseCursor,
    bool? enableFeedback,
    void Function(int)? onTap,
    ScrollPhysics? physics,
    InteractiveInkFeatureFactory? splashFactory,
    BorderRadius? splashBorderRadius,
  }) {
    return TabBar(
      key: key,
      tabs: tabs,
    );
  }

  Widget buildTabBarView({
    Key? key,
    required List<Widget> children,
    TabController? controller,
    ScrollPhysics? physics,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    double viewportFraction = 1.0,
  }) {
    return TabBarView(
      key: key,
      children: children,
    );
  }

  Widget buildTabPageSelector({
    Key? key,
    TabController? controller,
    double indicatorSize = 12.0,
    Color? color,
    Color? selectedColor,
    BorderStyle? borderStyle,
  }) {
    return TabPageSelector(key: key);
  }

  ///输入小控件
  Widget buildTextFormField({
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
    bool? enableInteractiveSelection,
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
    return TextFormField(
      key: key,
      controller: controller,
      initialValue: initialValue,
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
      onFieldSubmitted: onFieldSubmitted,
      onSaved: onSaved,
      validator: validator,
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
      autovalidateMode: autovalidateMode,
      scrollController: scrollController,
      restorationId: restorationId,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      mouseCursor: mouseCursor,
    );
  }

  Widget buildTextField({
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
    return TextField(
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
    );
  }

  Widget buildTextButton({
    Key? key,
    required void Function()? onPressed,
    void Function()? onLongPress,
    void Function(bool)? onHover,
    void Function(bool)? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    Clip clipBehavior = Clip.none,
    required Widget child,
  }) {
    return TextButton(
      key: key,
      onPressed: onPressed,
      child: child!,
    );
  }

  Widget buildRadio({
    Key? key,
    required dynamic value,
    required dynamic groupValue,
    required void Function(dynamic)? onChanged,
    MouseCursor? mouseCursor,
    bool toggleable = false,
    Color? activeColor,
    MaterialStateProperty? fillColor,
    Color? focusColor,
    Color? hoverColor,
    MaterialStateProperty? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Radio(
      onChanged: onChanged,
      value: value,
      groupValue: groupValue,
    );
  }

  Widget buildCheckbox({
    Key? key,
    required bool? value,
    bool tristate = false,
    required void Function(bool?)? onChanged,
    MouseCursor? mouseCursor,
    Color? activeColor,
    MaterialStateProperty? fillColor,
    Color? checkColor,
    Color? focusColor,
    Color? hoverColor,
    MaterialStateProperty? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
    OutlinedBorder? shape,
    BorderSide? side,
  }) {
    return Checkbox(
      onChanged: onChanged,
      value: value,
    );
  }

  Widget buildText(
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
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
  }) {
    return Text(
      data,
      key: key,
      textAlign: textAlign,
    );
  }

  Widget buildIcon(
    IconData? icon, {
    Key? key,
    double? size,
    Color? color,
    String? semanticLabel,
    TextDirection? textDirection,
    List? shadows,
  }) {
    return Icon(
      icon,
      key: key,
      size: size,
    );
  }

  Widget buildSwitch({
    Key? key,
    required bool value,
    required void Function(bool)? onChanged,
    Color? activeColor,
    Color? activeTrackColor,
    Color? inactiveThumbColor,
    Color? inactiveTrackColor,
    ImageProvider? activeThumbImage,
    void Function(Object, StackTrace?)? onActiveThumbImageError,
    ImageProvider? inactiveThumbImage,
    void Function(Object, StackTrace?)? onInactiveThumbImageError,
    MaterialStateProperty? thumbColor,
    MaterialStateProperty? trackColor,
    MaterialTapTargetSize? materialTapTargetSize,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    MouseCursor? mouseCursor,
    Color? focusColor,
    Color? hoverColor,
    MaterialStateProperty? overlayColor,
    double? splashRadius,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Switch(
      key: key,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget buildToggle({
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
    return ToggleButtons(
      key: key,
      isSelected: [],
      children: [],
    );
  }

  Widget buildSlider({
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
  }) {
    return Slider(
      key: key,
      onChanged: (double value) {},
      value: value,
    );
  }

  Widget buildProgress({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? color,
    Animation? valueColor,
    double? minHeight,
    String? semanticsLabel,
    String? semanticsValue,
  }) {
    return LinearProgressIndicator(
      key: key,
      value: value,
    );
  }

  Widget buildProgressIndeterminate({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? color,
    Animation? valueColor,
    double? minHeight,
    String? semanticsLabel,
    String? semanticsValue,
  }) {
    return LinearProgressIndicator(
      key: key,
    );
  }

  Widget buildChip({
    Key? key,
    Widget? avatar,
    required Widget label,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? labelPadding,
    Widget? deleteIcon,
    void Function()? onDeleted,
    Color? deleteIconColor,
    String? deleteButtonTooltipMessage,
    BorderSide? side,
    OutlinedBorder? shape,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? materialTapTargetSize,
    double? elevation,
    Color? shadowColor,
    bool useDeleteButtonTooltip = true,
  }) {
    return Chip(
      label: label,
    );
  }

  Widget buildCircularProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? color,
    Animation? valueColor,
    double strokeWidth = 4.0,
    String? semanticsLabel,
    String? semanticsValue,
  }) {
    return CircularProgressIndicator();
  }

  Widget buildDivider({
    Key? key,
    double? height,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
  }) {
    return Divider();
  }

  Widget buildListTile({
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
    EdgeInsetsGeometry? contentPadding,
    bool enabled = true,
    void Function()? onTap,
    void Function()? onLongPress,
    MouseCursor? mouseCursor,
    bool selected = false,
    Color? focusColor,
    Color? hoverColor,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    double? horizontalTitleGap,
    double? minVerticalPadding,
    double? minLeadingWidth,
  }) {
    return ListTile();
  }

  Widget buildStepper({
    Key? key,
    required List<Step> steps,
    ScrollPhysics? physics,
    StepperType type = StepperType.vertical,
    int currentStep = 0,
    void Function(int)? onStepTapped,
    void Function()? onStepContinue,
    void Function()? onStepCancel,
    Widget Function(BuildContext, ControlsDetails)? controlsBuilder,
    double? elevation,
    EdgeInsetsGeometry? margin,
  }) {
    return Stepper(
      steps: steps,
    );
  }

  Widget buildImage({
    Key? key,
    required ImageProvider image,
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? width,
    double? height,
    Color? color,
    Animation? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
  }) {
    return Image(
      image: image,
    );
  }

  Widget buildTooltip({
    Key? key,
    String? message,
    InlineSpan? richMessage,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? verticalOffset,
    bool? preferBelow,
    bool? excludeFromSemantics,
    Decoration? decoration,
    TextStyle? textStyle,
    Duration? waitDuration,
    Duration? showDuration,
    Widget? child,
    TooltipTriggerMode? triggerMode,
    bool? enableFeedback,
  }) {
    return Tooltip();
  }

  Widget buildBadge({
    Key? key,
    Widget? badgeContent,
    Widget? child,
    Color badgeColor = Colors.red,
    double elevation = 2,
    bool toAnimate = true,
    BadgePosition? position,
    BadgeShape shape = BadgeShape.circle,
    EdgeInsetsGeometry padding = const EdgeInsets.all(5.0),
    Duration animationDuration = const Duration(milliseconds: 500),
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
    AlignmentGeometry alignment = Alignment.center,
    BadgeAnimationType animationType = BadgeAnimationType.slide,
    bool showBadge = true,
    bool ignorePointer = false,
    BorderSide borderSide = BorderSide.none,
    StackFit stackFit = StackFit.loose,
    Gradient? gradient,
  }) {
    return Badge();
  }

  ///按钮
  Widget buildIconButton({
    Key? key,
    double? iconSize,
    VisualDensity? visualDensity,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    AlignmentGeometry alignment = Alignment.center,
    double? splashRadius,
    Color? color,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    Color? disabledColor,
    required void Function()? onPressed,
    MouseCursor? mouseCursor,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    bool enableFeedback = true,
    BoxConstraints? constraints,
    required Widget icon,
  }) {
    return IconButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
    );
  }

  Widget buildDropdownButton<T>({
    Key? key,
    required List? items,
    List Function(BuildContext)? selectedItemBuilder,
    dynamic value,
    Widget? hint,
    Widget? disabledHint,
    required void Function(Object)? onChanged,
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
  }) {
    return DropdownButton<T>(
      key: key,
      items: [],
      onChanged: (Object? value) {},
    );
  }

  Widget buildElevatedButton({
    Key? key,
    required void Function()? onPressed,
    void Function()? onLongPress,
    void Function(bool)? onHover,
    void Function(bool)? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    Clip clipBehavior = Clip.none,
    required Widget? child,
  }) {
    return ElevatedButton(
      key: key,
      onPressed: () {},
      child: null,
    );
  }

  Widget buildFloatingActionButton({
    Key? key,
    Widget? child,
    String? tooltip,
    Color? foregroundColor,
    Color? backgroundColor,
    Color? focusColor,
    Color? hoverColor,
    Color? splashColor,
    Object? heroTag,
    double? elevation,
    double? focusElevation,
    double? hoverElevation,
    double? highlightElevation,
    double? disabledElevation,
    required void Function()? onPressed,
    MouseCursor? mouseCursor,
    bool mini = false,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    MaterialTapTargetSize? materialTapTargetSize,
    bool isExtended = false,
    bool? enableFeedback,
  }) {
    return FloatingActionButton(
      key: key,
      onPressed: () {},
    );
  }

  Widget buildOutlinedButton({
    Key? key,
    required void Function()? onPressed,
    void Function()? onLongPress,
    void Function(bool)? onHover,
    void Function(bool)? onFocusChange,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    Clip clipBehavior = Clip.none,
    required Widget child,
  }) {
    return OutlinedButton(
      key: key,
      onPressed: () {},
      child: child,
    );
  }

  Widget buildPopupMenuButton({
    Key? key,
    required List<PopupMenuEntry<dynamic>> Function(BuildContext) itemBuilder,
    dynamic initialValue,
    void Function(dynamic)? onSelected,
    void Function()? onCanceled,
    String? tooltip,
    double? elevation,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    Widget? child,
    double? splashRadius,
    Widget? icon,
    double? iconSize,
    Offset offset = Offset.zero,
    bool enabled = true,
    ShapeBorder? shape,
    Color? color,
    bool? enableFeedback,
    BoxConstraints? constraints,
    PopupMenuPosition position = PopupMenuPosition.over,
  }) {
    return PopupMenuButton(
      key: key,
      itemBuilder: itemBuilder,
    );
  }

  ///对话框和展示页面
  Widget buildBottomSheet({
    Key? key,
    AnimationController? animationController,
    bool enableDrag = true,
    void Function(DragStartDetails)? onDragStart,
    void Function(DragEndDetails, {required bool isClosing})? onDragEnd,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    required void Function() onClosing,
    required Widget Function(BuildContext) builder,
  }) {
    return BottomSheet(
      key: key,
      builder: builder,
      onClosing: () {},
    );
  }

  Widget buildSnackBar({
    Key? key,
    required Widget content,
    Color? backgroundColor,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? width,
    ShapeBorder? shape,
    SnackBarBehavior? behavior,
    SnackBarAction? action,
    Duration duration = const Duration(milliseconds: 4000),
    Animation? animation,
    void Function()? onVisible,
    DismissDirection dismissDirection = DismissDirection.down,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return SnackBar(
      content: content,
    );
  }

  Widget buildSimpleDialog({
    Key? key,
    Widget? title,
    EdgeInsetsGeometry titlePadding =
        const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
    TextStyle? titleTextStyle,
    List? children,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
    Color? backgroundColor,
    double? elevation,
    String? semanticLabel,
    EdgeInsets insetPadding =
        const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
    Clip clipBehavior = Clip.none,
    ShapeBorder? shape,
    AlignmentGeometry? alignment,
  }) {
    return SimpleDialog();
  }

  Widget buildAlertDialog({
    Key? key,
    Widget? title,
    EdgeInsetsGeometry? titlePadding,
    TextStyle? titleTextStyle,
    Widget? content,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
    TextStyle? contentTextStyle,
    List? actions,
    EdgeInsetsGeometry actionsPadding = EdgeInsets.zero,
    MainAxisAlignment? actionsAlignment,
    OverflowBarAlignment? actionsOverflowAlignment,
    VerticalDirection? actionsOverflowDirection,
    double? actionsOverflowButtonSpacing,
    EdgeInsetsGeometry? buttonPadding,
    Color? backgroundColor,
    double? elevation,
    String? semanticLabel,
    EdgeInsets insetPadding =
        const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
    Clip clipBehavior = Clip.none,
    ShapeBorder? shape,
    AlignmentGeometry? alignment,
    bool scrollable = false,
  }) {
    return AlertDialog();
  }

  Widget showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? currentDate,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    bool Function(DateTime)? selectableDayPredicate,
    String? helpText,
    String? cancelText,
    String? confirmText,
    Locale? locale,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    TextDirection? textDirection,
    Widget Function(BuildContext, Widget?)? builder,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    String? errorFormatText,
    String? errorInvalidText,
    String? fieldHintText,
    String? fieldLabelText,
    TextInputType? keyboardType,
    Offset? anchorPoint,
  }) {
    return showDatePicker(
        firstDate: firstDate,
        lastDate: lastDate,
        context: context,
        initialDate: initialDate);
  }

  Widget buildApp(
    BuildContext context, {
    Key? key,
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey? scaffoldMessengerKey,
    Widget? home,
    Map<String, Widget Function(BuildContext)> routes = const {},
    String? initialRoute,
    Route? Function(RouteSettings)? onGenerateRoute,
    List<Route<dynamic>> Function(String)? onGenerateInitialRoutes,
    Route? Function(RouteSettings)? onUnknownRoute,
    List<NavigatorObserver> navigatorObservers = const [],
    Widget Function(BuildContext, Widget?)? builder,
    String title = '',
    String Function(BuildContext)? onGenerateTitle,
    Color? color,
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeData? highContrastTheme,
    ThemeData? highContrastDarkTheme,
    ThemeMode? themeMode = ThemeMode.system,
    Locale? locale,
    Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
    Locale? Function(List?, Iterable)? localeListResolutionCallback,
    Locale? Function(Locale?, Iterable)? localeResolutionCallback,
    Iterable<Locale> supportedLocales = const [Locale('en', 'US')],
    bool debugShowMaterialGrid = false,
    bool showPerformanceOverlay = false,
    bool checkerboardRasterCacheImages = false,
    bool checkerboardOffscreenLayers = false,
    bool showSemanticsDebugger = false,
    bool debugShowCheckedModeBanner = true,
    Map<ShortcutActivator, Intent>? shortcuts,
    Map<Type, Action<Intent>>? actions,
    String? restorationScopeId,
    ScrollBehavior? scrollBehavior,
    bool useInheritedMediaQuery = false,
  }) {
    onGenerateTitle = onGenerateTitle ??
        (context) {
          return AppLocalizations.instance.text('Welcome to CollaChat');
        };
    themeMode = themeMode ?? appDataProvider.themeMode;
    theme = theme ?? appDataProvider.themeData;
    //darkTheme = darkTheme ?? appDataProvider.darkThemeData;
    onGenerateRoute = onGenerateRoute ?? Application.router.generator;
    // AppLocalizations.localizationsDelegates,
    localizationsDelegates = const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    supportedLocales = const [
      Locale('zh', 'CN'),
      Locale('en', 'US'),
      Locale('zh', 'TW'),
      Locale('ja', 'JP'),
      Locale('ko', 'KR'),
    ];
    locale = locale ?? Provider.of<AppDataProvider>(context).getLocale();
    return MaterialApp(
      key: key,
      title: title,
      color: color,
      initialRoute: initialRoute,
      routes: routes,
      home: home,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner = true,
      navigatorKey: navigatorKey,
      navigatorObservers: navigatorObservers,
      onGenerateRoute: onGenerateRoute,
      onGenerateTitle: onGenerateTitle,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      onUnknownRoute: onUnknownRoute,
      theme: theme,
      darkTheme: darkTheme,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      themeMode: themeMode,
      builder: builder,
      localeResolutionCallback: localeResolutionCallback,
      highContrastTheme: highContrastTheme,
      highContrastDarkTheme: highContrastDarkTheme,
      localeListResolutionCallback: localeListResolutionCallback,
      showPerformanceOverlay: showPerformanceOverlay,
      checkerboardRasterCacheImages: checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      showSemanticsDebugger: showSemanticsDebugger,
      debugShowMaterialGrid: debugShowMaterialGrid,
      shortcuts: shortcuts,
      actions: actions,
    );
  }

  Widget buildScaffold({
    Key? key,
    PreferredSizeWidget? appBar,
    Widget? body,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    FloatingActionButtonAnimator? floatingActionButtonAnimator,
    List? persistentFooterButtons,
    Widget? drawer,
    void Function(bool)? onDrawerChanged,
    Widget? endDrawer,
    void Function(bool)? onEndDrawerChanged,
    Widget? bottomNavigationBar,
    Widget? bottomSheet,
    Color? backgroundColor,
    bool? resizeToAvoidBottomInset,
    bool primary = true,
    DragStartBehavior drawerDragStartBehavior = DragStartBehavior.start,
    bool extendBody = false,
    bool extendBodyBehindAppBar = false,
    Color? drawerScrimColor,
    double? drawerEdgeDragWidth,
    bool drawerEnableOpenDragGesture = true,
    bool endDrawerEnableOpenDragGesture = true,
    String? restorationId,
  }) {
    return Scaffold(
      key: key,
    );
  }

  Widget buildAppBar({
    Key? key,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Widget? title,
    List? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
    double? elevation,
    double? scrolledUnderElevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Color? backgroundColor,
    Color? foregroundColor,
    Brightness? brightness,
    IconThemeData? iconTheme,
    IconThemeData? actionsIconTheme,
    TextTheme? textTheme,
    bool primary = true,
    bool? centerTitle,
    bool excludeHeaderSemantics = false,
    double? titleSpacing,
    double toolbarOpacity = 1.0,
    double bottomOpacity = 1.0,
    double? toolbarHeight,
    double? leadingWidth,
    bool? backwardsCompatibility,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    return AppBar(
      key: key,
      title: title,
      iconTheme: iconTheme,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
    );
  }

  Widget buildSliverAppBar({
    Key? key,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Widget? title,
    List? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
    double? elevation,
    double? scrolledUnderElevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    bool forceElevated = false,
    Color? backgroundColor,
    Color? foregroundColor,
    Brightness? brightness,
    IconThemeData? iconTheme,
    IconThemeData? actionsIconTheme,
    TextTheme? textTheme,
    bool primary = true,
    bool? centerTitle,
    bool excludeHeaderSemantics = false,
    double? titleSpacing,
    double? collapsedHeight,
    double? expandedHeight,
    bool floating = false,
    bool pinned = false,
    bool snap = false,
    bool stretch = false,
    double stretchTriggerOffset = 100.0,
    Future Function()? onStretchTrigger,
    ShapeBorder? shape,
    double toolbarHeight = kToolbarHeight,
    double? leadingWidth,
    bool? backwardsCompatibility,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    return SliverAppBar();
  }

  Widget buildDrawer({
    Key? key,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    double? width,
    Widget? child,
    String? semanticLabel,
  }) {
    return Drawer(key: key);
  }

  Widget buildBottomNavigationBar({
    Key? key,
    required List<BottomNavigationBarItem> items,
    void Function(int)? onTap,
    int currentIndex = 0,
    double? elevation,
    BottomNavigationBarType? type,
    Color? fixedColor,
    Color? backgroundColor,
    double iconSize = 24.0,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    IconThemeData? selectedIconTheme,
    IconThemeData? unselectedIconTheme,
    double selectedFontSize = 14.0,
    double unselectedFontSize = 12.0,
    TextStyle? selectedLabelStyle,
    TextStyle? unselectedLabelStyle,
    bool? showSelectedLabels,
    bool? showUnselectedLabels,
    MouseCursor? mouseCursor,
    bool? enableFeedback,
    BottomNavigationBarLandscapeLayout? landscapeLayout,
  }) {
    return BottomNavigationBar(
      key: key,
      items: items,
    );
  }
}

final MaterialWidgetFactory materialWidgetFactory = MaterialWidgetFactory();
