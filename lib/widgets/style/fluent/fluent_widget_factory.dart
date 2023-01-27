import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

///只适合桌面和web，样式是windows样式
class FluentWidgetFactory extends WidgetFactory {
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

  @override
  Widget buildSizedBox({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    required double width,
    required double height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Widget? child,
    Clip clipBehavior = Clip.none,
  }) {
    return Container(
      key: key,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      child: child,
    );
  }

  Widget buildTextFormField({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    FocusNode? focusNode,
    material.InputDecoration? decoration = const material.InputDecoration(),
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
    material.InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    AutovalidateMode? autovalidateMode,
    ScrollController? scrollController,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
  }) {
    return TextFormBox(
      key: key,
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      //decoration: decoration,
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
      //cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      //enableInteractiveSelection: enableInteractiveSelection,
      selectionControls: selectionControls,
      //buildCounter: buildCounter,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      //autovalidateMode: autovalidateMode,
      scrollController: scrollController,
      restorationId: restorationId,
      //enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      // mouseCursor: mouseCursor,
    );
  }

  Widget buildTextField({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    material.InputDecoration? decoration = const material.InputDecoration(),
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
    material.InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    ScrollController? scrollController,
    String? restorationId,
    bool enableIMEPersonalizedLearning = true,
    MouseCursor? mouseCursor,
  }) {
    return TextBox(
      key: key,
      controller: controller,
      focusNode: focusNode,
      //decoration: decoration,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: style,
      strutStyle: strutStyle,
      //textDirection: textDirection,
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
      // enableInteractiveSelection: enableInteractiveSelection,
      // selectionControls: selectionControls,
      // buildCounter: buildCounter,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      scrollController: scrollController,
      restorationId: restorationId,
      // enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      // mouseCursor: mouseCursor,
    );
  }

  Widget buildButton({
    Key? key,
    required Widget child,
    required void Function()? onPressed,
    void Function()? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    ButtonStyle? style,
  }) {
    return Button(
      key: key,
      style: style,
      onPressed: () {},
      child: child,
    );
  }

  Widget buildRadio({
    Key? key,
    required bool checked,
    required void Function(bool)? onChanged,
    RadioButtonThemeData? style,
    Widget? content,
    String? semanticLabel,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return RadioButton(
      style: style,
      onChanged: onChanged,
      checked: checked,
    );
  }

  Widget buildCheckbox({
    Key? key,
    required bool? checked,
    required void Function(bool?)? onChanged,
    CheckboxThemeData? style,
    Widget? content,
    String? semanticLabel,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Checkbox(
      style: style,
      onChanged: onChanged,
      checked: checked,
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
      style: style,
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
    required bool checked,
    required void Function(bool)? onChanged,
    ToggleSwitchThemeData? style,
    Widget? content,
    String? semanticLabel,
    Widget? thumb,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return ToggleSwitch(
      key: key,
      style: style,
      onChanged: onChanged,
      checked: checked,
    );
  }

  Widget buildToggle({
    Key? key,
    required bool checked,
    required void Function(bool)? onChanged,
    ToggleSwitchThemeData? style,
    Widget? content,
    String? semanticLabel,
    Widget? thumb,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return ToggleSwitch(
      key: key,
      style: style,
      thumb: thumb,
      onChanged: onChanged,
      checked: checked,
    );
  }

  Widget buildSlider({
    Key? key,
    required double value,
    required void Function(double)? onChanged,
    void Function(double)? onChangeStart,
    void Function(double)? onChangeEnd,
    double min = 0.0,
    double max = 100.0,
    int? divisions,
    SliderThemeData? style,
    String? label,
    FocusNode? focusNode,
    bool vertical = false,
    bool autofocus = false,
    MouseCursor mouseCursor = MouseCursor.defer,
  }) {
    return Slider(
      key: key,
      style: style,
      min: min,
      value: value,
      max: max,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );
  }

  Widget buildProgress({
    Key? key,
    double? value,
    double strokeWidth = 4.5,
    String? semanticLabel,
    Color? backgroundColor,
    Color? activeColor,
  }) {
    return ProgressBar(
      key: key,
    );
  }

  Widget buildProgressIndeterminate({
    Key? key,
    double? value,
    double strokeWidth = 4.5,
    String? semanticLabel,
    Color? backgroundColor,
    Color? activeColor,
  }) {
    return ProgressBar(
      key: key,
    );
  }

  Widget buildBackground({
    Key? key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12.0),
    Color? backgroundColor,
    double elevation = 4.0,
    BorderRadiusGeometry borderRadius =
        const BorderRadius.all(Radius.circular(6.0)),
  }) {
    return Card(
      padding: padding,
      borderRadius: borderRadius,
      child: child,
    );
  }

  ///与其他的样式设计不同，
  Widget buildApp(
    BuildContext context, {
    Key? key,
    GlobalKey<NavigatorState>? navigatorKey,
    Route? Function(RouteSettings)? onGenerateRoute,
    List<Route<dynamic>> Function(String)? onGenerateInitialRoutes,
    Route? Function(RouteSettings)? onUnknownRoute,
    List<NavigatorObserver>? navigatorObservers = const [],
    String? initialRoute,
    Widget? home,
    Map<String, Widget Function(BuildContext)>? routes = const {},
    Widget Function(BuildContext, Widget?)? builder,
    String title = '',
    String Function(BuildContext)? onGenerateTitle,
    Color? color,
    Locale? locale,
    Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
    Locale? Function(List?, Iterable)? localeListResolutionCallback,
    Locale? Function(Locale?, Iterable)? localeResolutionCallback,
    Iterable<Locale> supportedLocales = defaultSupportedLocales,
    bool showPerformanceOverlay = false,
    bool checkerboardRasterCacheImages = false,
    bool checkerboardOffscreenLayers = false,
    bool showSemanticsDebugger = false,
    bool debugShowCheckedModeBanner = true,
    Map<LogicalKeySet, Intent>? shortcuts,
    Map<Type, Action<Intent>>? actions,
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
    String? restorationScopeId,
    ScrollBehavior scrollBehavior = const FluentScrollBehavior(),
    bool useInheritedMediaQuery = false,
  }) {
    onGenerateTitle = onGenerateTitle ??
        (context) {
          return AppLocalizations.t('Welcome to CollaChat');
        };
    themeMode = themeMode ?? myself.themeMode;
    // theme = myself.themeData;
    // darkTheme = darkTheme ?? myself.darkThemeData;
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
    locale = locale ?? myself.locale;
    return FluentApp(
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
      // highContrastTheme: highContrastTheme,
      // highContrastDarkTheme: highContrastDarkTheme,
      localeListResolutionCallback: localeListResolutionCallback,
      showPerformanceOverlay: showPerformanceOverlay,
      checkerboardRasterCacheImages: checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      showSemanticsDebugger: showSemanticsDebugger,
      //debugShowMaterialGrid: debugShowMaterialGrid,
      shortcuts: shortcuts,
      actions: actions,
    );
  }

  Widget buildScaffoldPage({
    Key? key,
    Widget? header,
    Widget content = const SizedBox.expand(),
    Widget? bottomBar,
    EdgeInsets? padding,
  }) {
    return ScaffoldPage(
      key: key,
    );
  }

  Widget buildNavigationView({
    Key? key,
    NavigationAppBar? appBar,
    NavigationPane? pane,
    Widget content = const SizedBox.shrink(),
    Clip clipBehavior = Clip.antiAlias,
    ShapeBorder? contentShape,
  }) {
    return NavigationView(
      key: key,
    );
  }

  NavigationPane buildNavigationPane({
    Key? key,
    int? selected,
    void Function(int)? onChanged,
    NavigationPaneSize? size,
    Widget? header,
    List items = const [],
    List footerItems = const [],
    Widget? autoSuggestBox,
    Widget? autoSuggestBoxReplacement,
    PaneDisplayMode displayMode = PaneDisplayMode.auto,
    NavigationPaneWidget? customPane,
    Widget? menuButton,
    ScrollController? scrollController,
    Widget? leading,
    Widget? indicator = const StickyNavigationIndicator(),
  }) {
    return NavigationPane(
      key: key,
    );
  }

  NavigationAppBar buildAppBar({
    Key? key,
    Widget? leading,
    Widget? title,
    Widget? actions,
    bool automaticallyImplyLeading = true,
    double height = 50,
    Color? backgroundColor,
  }) {
    return NavigationAppBar(
      key: key,
      title: title,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  ///与其他的样式设计不同
  Widget buildNavigationBody({
    Key? key,
    required int index,
    required List<Widget> children,
    Widget Function(Widget, Animation)? transitionBuilder,
    Curve? animationCurve,
    Duration? animationDuration,
  }) {
    return NavigationBody(
      key: key,
      index: index,
      children: children,
    );
  }
}

final FluentWidgetFactory neumorphicWidgetFactory = FluentWidgetFactory();
