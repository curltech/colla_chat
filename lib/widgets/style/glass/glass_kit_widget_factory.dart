import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glass_kit/glass_kit.dart';

final defaultLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(AppOpacity.lgOpacity),
      Colors.white.withOpacity(AppOpacity.xlOpacity),
    ],
    stops: const [
      AppOpacity.lgOpacity,
      AppOpacity.xsOpacity,
    ]);
final defaultBorderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Colors.white.withOpacity(AppOpacity.lgOpacity),
    Colors.white.withOpacity(AppOpacity.lgOpacity),
  ],
);

final primaryLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      myself.primary.withOpacity(AppOpacity.smOpacity),
      myself.primary.withOpacity(AppOpacity.xsOpacity),
    ],
    stops: const [
      AppOpacity.lgOpacity,
      AppOpacity.xsOpacity,
    ]);
final primaryBorderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    myself.primary.withOpacity(AppOpacity.smOpacity),
    myself.primary.withOpacity(AppOpacity.smOpacity),
  ],
);

const double blur = 20;
const BorderRadius borderRadius = BorderRadius.zero;

class GlassKitWidgetFactory extends WidgetFactory {
  Widget clearGlass({
    Key? key,
    required double height,
    required double width,
    AlignmentGeometry? alignment,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Gradient? gradient,
    Color? color,
    BorderRadius? borderRadius = borderRadius,
    double? borderWidth,
    Gradient? borderGradient,
    Color? borderColor,
    double? blur = blur,
    double? elevation,
    Color? shadowColor,
    BoxShape shape = BoxShape.rectangle,
    Widget? child,
  }) {
    return GlassContainer.clearGlass(
        key: key,
        height: height,
        width: width,
        alignment: alignment,
        transform: transform,
        transformAlignment: transformAlignment,
        padding: padding,
        margin: margin,
        gradient: gradient,
        color: color,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderGradient: borderGradient,
        borderColor: borderColor,
        blur: blur,
        elevation: elevation,
        shadowColor: shadowColor,
        shape: shape,
        child: child);
  }

  Widget frostedGlass({
    Key? key,
    required double height,
    required double width,
    AlignmentGeometry? alignment,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Gradient? gradient,
    Color? color,
    BorderRadius? borderRadius = borderRadius,
    double? borderWidth,
    Gradient? borderGradient,
    Color? borderColor,
    double? blur = blur,
    double? elevation,
    Color? shadowColor,
    BoxShape shape = BoxShape.rectangle,
    double? frostedOpacity,
    Widget? child,
  }) {
    return GlassContainer.frostedGlass(
        key: key,
        height: height,
        width: width,
        alignment: alignment,
        transform: transform,
        transformAlignment: transformAlignment,
        padding: padding,
        margin: margin,
        gradient: gradient,
        color: color,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderGradient: borderGradient,
        borderColor: borderColor,
        blur: blur,
        elevation: elevation,
        shadowColor: shadowColor,
        shape: shape,
        frostedOpacity: frostedOpacity,
        child: child);
  }

  @override
  Widget sizedBox({
    Key? key,
    double? width,
    double? height,
    Widget? child,
  }) {
    return GlassContainer(
      key: key,
      height: height,
      width: width,
      gradient: defaultLinearGradient,
      borderRadius: borderRadius,
      borderGradient: defaultBorderGradient,
      blur: blur,
      isFrostedGlass: false,
      shape: BoxShape.rectangle,
      child: child,
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
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return GlassContainer(
        key: key,
        height: constraints.maxHeight,
        width: constraints.maxWidth,
        alignment: alignment,
        transform: transform,
        transformAlignment: transformAlignment,
        padding: padding,
        margin: margin,
        color: color,
        gradient: defaultLinearGradient,
        borderRadius: borderRadius,
        borderGradient: defaultBorderGradient,
        blur: blur,
        isFrostedGlass: false,
        shape: BoxShape.rectangle,
        child: child,
      );
    });
  }

  _buildGlassWidget({required Widget child}) {
    return GlassContainer(
      isFrostedGlass: true,
      frostedOpacity: 0.05,
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.60),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.60),
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20.0)
      ],
      borderRadius: BorderRadius.circular(25.0),
      padding: const EdgeInsets.all(16.0),
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
    return _buildGlassWidget(
        child: super.appBar(
      key: key,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: title,
      actions: actions,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      notificationPredicate: notificationPredicate,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      iconTheme: iconTheme,
      actionsIconTheme: actionsIconTheme,
      primary: primary,
      centerTitle: centerTitle,
      excludeHeaderSemantics: excludeHeaderSemantics,
      titleSpacing: titleSpacing,
      toolbarOpacity: toolbarOpacity,
      bottomOpacity: bottomOpacity,
      toolbarHeight: toolbarHeight,
      leadingWidth: leadingWidth,
      toolbarTextStyle: toolbarTextStyle,
      titleTextStyle: titleTextStyle,
      systemOverlayStyle: systemOverlayStyle,
      forceMaterialTransparency: forceMaterialTransparency,
      clipBehavior: clipBehavior,
    ));
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
    return _buildGlassWidget(
        child: bottomNavigationBar(
      key: key,
      items: items,
      currentIndex: currentIndex,
      selectedItemColor: selectedItemColor,
      selectedColorOpacity: selectedColorOpacity,
      onTap: onTap,
      unselectedItemColor: unselectedItemColor,
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
    return _buildGlassWidget(
        child: button(
      key: key,
      onPressed: onPressed,
      child: child,
    ));
  }

  @override
  icon(
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
    return _buildGlassWidget(
        child: Icon(
      icon,
      key: key,
      size: size,
      fill: fill,
      weight: weight,
      grade: grade,
      opticalSize: opticalSize,
      color: color,
      shadows: shadows,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      applyTextScaling: applyTextScaling,
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
    return _buildGlassWidget(
        child: ListTile(
            key: key,
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            onTap: onTap));
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
    return _buildGlassWidget(
        child: CommonAutoSizeText(
      data,
      key: key,
      style: textStyle,
      textAlign: textAlign,
      wrapWords: wrapWords,
      overflow: overflow,
      overflowReplacement: overflowReplacement,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
    ));
  }
}

final GlassKitWidgetFactory glassKitWidgetFactory = GlassKitWidgetFactory();
