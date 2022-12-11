import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/widgets/style/neumorphic/neumorphic_container_widget.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:provider/provider.dart';

class NeumorphicWidgetFactory extends WidgetFactory {
  NeumorphicTheme buildTheme(Widget child) {
    ThemeMode themeMode = appDataProvider.themeMode;
    var theme = NeumorphicTheme(
        themeMode: themeMode, //or dark / system
        darkTheme: neumorphicConstants.darkThemeData,
        theme: neumorphicConstants.themeData,
        child: child);
    return theme;
  }

  @override
  Widget buildContainer({
    Key? key,
    Widget? child,
    Duration duration = Neumorphic.DEFAULT_DURATION,
    Curve curve = Neumorphic.DEFAULT_CURVE,
    NeumorphicStyle? style,
    TextStyle? textStyle,
    EdgeInsets margin = const EdgeInsets.all(0),
    EdgeInsets padding = const EdgeInsets.all(0),
    bool drawSurfaceAboveChild = true,
  }) {
    return Neumorphic(
      key: key,
      duration: duration,
      curve: curve,
      style: style,
      textStyle: textStyle,
      margin: margin,
      padding: padding,
      drawSurfaceAboveChild: drawSurfaceAboveChild,
      child: child,
    );
  }

  @override
  Widget buildSizedBox({
    Key? key,
    required double width,
    required double height,
    Widget? child,
    Duration duration = Neumorphic.DEFAULT_DURATION,
    Curve curve = Neumorphic.DEFAULT_CURVE,
    NeumorphicStyle? style,
    TextStyle? textStyle,
    EdgeInsets margin = const EdgeInsets.all(0),
    EdgeInsets padding = const EdgeInsets.all(0),
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
          textStyle: textStyle,
          margin: margin,
          padding: padding,
          drawSurfaceAboveChild: drawSurfaceAboveChild,
          child: child,
        ));
  }

  Widget buildCard({
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
    return Neumorphic(
        child: TextFormField(
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
    ));
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

  Widget buildButton({
    Key? key,
    EdgeInsets? padding,
    EdgeInsets? margin = EdgeInsets.zero,
    Widget? child,
    String? tooltip,
    bool drawSurfaceAboveChild = true,
    bool? pressed,
    Duration duration = Neumorphic.DEFAULT_DURATION,
    Curve curve = Neumorphic.DEFAULT_CURVE,
    void Function()? onPressed,
    double minDistance = 0,
    NeumorphicStyle? style,
    bool provideHapticFeedback = true,
  }) {
    return NeumorphicButton(
      key: key,
      padding: padding,
      margin: margin,
      tooltip: tooltip,
      drawSurfaceAboveChild: drawSurfaceAboveChild,
      pressed: pressed,
      duration: duration,
      curve: curve,
      onPressed: onPressed,
      minDistance: minDistance,
      style: style,
      provideHapticFeedback: provideHapticFeedback,
      child: child,
    );
  }

  Widget buildRadio({
    Widget? child,
    NeumorphicRadioStyle style = const NeumorphicRadioStyle(),
    dynamic value,
    Curve curve = Neumorphic.DEFAULT_CURVE,
    Duration duration = Neumorphic.DEFAULT_DURATION,
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

  Widget buildCheckbox({
    NeumorphicCheckboxStyle style = const NeumorphicCheckboxStyle(),
    required bool value,
    required void Function(dynamic) onChanged,
    Curve curve = Neumorphic.DEFAULT_CURVE,
    Duration duration = Neumorphic.DEFAULT_DURATION,
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

  Widget buildText(
    String text, {
    Key? key,
    Duration duration = Neumorphic.DEFAULT_DURATION,
    Curve curve = Neumorphic.DEFAULT_CURVE,
    NeumorphicStyle? style,
    TextAlign textAlign = TextAlign.center,
    NeumorphicTextStyle? textStyle,
  }) {
    return NeumorphicText(
      text,
      key: key,
      duration: duration,
      style: style,
      curve: curve,
      textAlign: textAlign,
      textStyle: textStyle,
    );
  }

  Widget buildIcon(
    IconData icon, {
    Key? key,
    Duration duration = Neumorphic.DEFAULT_DURATION,
    Curve curve = Neumorphic.DEFAULT_CURVE,
    NeumorphicStyle? style,
    double size = 20,
  }) {
    return NeumorphicIcon(
      icon,
      key: key,
      duration: duration,
      style: style,
      curve: curve,
      size: size,
    );
  }

  Widget buildSwitch({
    NeumorphicSwitchStyle style = const NeumorphicSwitchStyle(),
    Key? key,
    Curve curve = Neumorphic.DEFAULT_CURVE,
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

  Widget buildToggle({
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

  Widget buildSlider({
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

  Widget buildProgress({
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

  Widget buildProgressIndeterminate({
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

  Widget buildApp(
    BuildContext context, {
    Key? key,
    String title = '',
    Color? color,
    String? initialRoute,
    Map<String, Widget Function(BuildContext)> routes = const {},
    Widget? home,
    bool debugShowCheckedModeBanner = false,
    GlobalKey<NavigatorState>? navigatorKey,
    List<NavigatorObserver> navigatorObservers = const [],
    Route? Function(RouteSettings)? onGenerateRoute,
    String Function(BuildContext)? onGenerateTitle,
    List<Route<dynamic>> Function(String)? onGenerateInitialRoutes,
    Route? Function(RouteSettings)? onUnknownRoute,
    NeumorphicThemeData? theme,
    NeumorphicThemeData? darkTheme,
    Locale? locale,
    Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
    Iterable<Locale>? supportedLocales,
    ThemeMode? themeMode,
    ThemeData? materialDarkTheme,
    ThemeData? materialTheme,
    Widget Function(BuildContext, Widget?)? builder,
    Locale? Function(Locale?, Iterable)? localeResolutionCallback,
    ThemeData? highContrastTheme,
    ThemeData? highContrastDarkTheme,
    Locale? Function(List?, Iterable)? localeListResolutionCallback,
    bool showPerformanceOverlay = false,
    bool checkerboardRasterCacheImages = false,
    bool checkerboardOffscreenLayers = false,
    bool showSemanticsDebugger = false,
    bool debugShowMaterialGrid = false,
    Map<LogicalKeySet, Intent>? shortcuts,
    Map<Type, Action<Intent>>? actions,
  }) {
    onGenerateTitle = onGenerateTitle ??
        (context) {
          return AppLocalizations.t('Welcome to CollaChat');
        };
    themeMode = themeMode ?? neumorphicConstants.themeMode;
    theme = theme ?? neumorphicConstants.themeData;
    darkTheme = darkTheme ?? neumorphicConstants.darkThemeData;
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
    return NeumorphicApp(
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
      materialDarkTheme: materialDarkTheme,
      materialTheme: materialTheme,
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

  Widget buildAppBar({
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
}

final NeumorphicWidgetFactory neumorphicWidgetFactory =
    NeumorphicWidgetFactory();
