import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../routers/routes.dart';

class NeumorphicContainerWidget extends StatelessWidget {
  final Widget? child;
  late final NeumorphicShape shape;
  late final LightSource lightSource;
  late final NeumorphicBorder border;
  late final Color? color;
  late final NeumorphicBoxShape? boxShape;
  final Color? shadowLightColor;
  final Color? shadowDarkColor;
  final Color? shadowLightColorEmboss;
  final Color? shadowDarkColorEmboss;
  late final double? depth;
  final double? intensity;
  late final double surfaceIntensity;
  final bool? disableDepth;
  late final bool oppositeShadowLightSource;

  NeumorphicContainerWidget({
    Key? key,
    this.child,
    this.shadowLightColor,
    this.shadowDarkColor,
    this.shadowLightColorEmboss,
    this.shadowDarkColorEmboss,
    this.disableDepth,
    this.intensity,
    NeumorphicShape shape = NeumorphicShape.concave,
    LightSource lightSource = LightSource.topLeft,
    NeumorphicBorder border = const NeumorphicBorder.none(),
    Color? color = Colors.grey,
    NeumorphicBoxShape? boxShape,
    double? depth = 8,
    double surfaceIntensity = 0.25,
    bool oppositeShadowLightSource = false,
  }) : super(key: key) {
    if (boxShape == null) {
      this.boxShape = NeumorphicBoxShape.roundRect(BorderRadius.circular(12));
    } else {
      this.boxShape = boxShape;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
          shape: shape,
          boxShape: boxShape,
          depth: depth,
          lightSource: lightSource,
          color: color),
      child: child,
    );
  }
}

class NeumorphicAppUtil {
  static NeumorphicTheme buildNeumorphicTheme({required Widget child}) {
    var themeData = appDataProvider.themeData;
    Color primary = themeData!.colorScheme.primary;
    Color secondary = themeData!.colorScheme.secondary;
    ThemeMode themeMode = appDataProvider.themeMode;
    LightSource lightSource = LightSource.topLeft;
    double depth = 6;
    double intensity = 0.5;
    var neumorphicTheme = NeumorphicTheme(
        themeMode: themeMode, //or dark / system
        darkTheme: NeumorphicThemeData(
          baseColor: primary,
          accentColor: secondary,
          lightSource: lightSource,
          depth: depth,
          intensity: intensity,
        ),
        theme: NeumorphicThemeData(
          baseColor: primary,
          accentColor: secondary,
          lightSource: lightSource,
          depth: depth,
          intensity: intensity,
        ),
        child: child);
    return neumorphicTheme;
  }

  static NeumorphicApp buildNeumorphicApp(BuildContext context, Widget child) {
    var theme = buildNeumorphicTheme(child: child);
    return NeumorphicApp(
      onGenerateTitle: (context) {
        return AppLocalizations.instance.text('Welcome to CollaChat');
      },
      //title: 'Welcome to CollaChat',
      debugShowCheckedModeBanner: false,
      themeMode: theme.themeMode,
      theme: theme.theme,
      darkTheme: theme.darkTheme,
      onGenerateRoute: Application.router.generator,
      // AppLocalizations.localizationsDelegates,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
        Locale('zh', 'TW'),
        Locale('ja', 'JP'),
        Locale('ko', 'KR'),
      ],
      locale: Provider.of<AppDataProvider>(context).getLocale(),
      home: child,
    );
  }

  static buildNeumorphicTextStyle() {
    var themeData = appDataProvider.themeData;
    var textTheme = themeData!.textTheme;
    return NeumorphicTextStyle(
      fontSize: 18,
    );
  }
}
