import 'package:colla_chat/pages/loading.dart';
import 'package:colla_chat/provider/locale_data.dart';
import 'package:colla_chat/provider/theme_data.dart';
import 'package:colla_chat/routers/application.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'l10n/localization.dart';

void main() {
  //初始化服务类
  // 也初始化了Provider管理的全局状态数据
  //  多状态的MultiProvider(
  //       providers: [
  //         ChangeNotifierProvider(create: (context) => AppProfile()),
  //         Provider(create: (context) => AppProfile()),
  //       ],
  WidgetsFlutterBinding.ensureInitialized();
  ServiceLocator.init().then((value) {
    runApp(MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => ThemeDataProvider()),
      ChangeNotifierProvider(create: (context) => LocaleDataProvider()),
    ], child: const CollaChatApp()));
  });
}

///应用是一个无态的组件
class CollaChatApp extends StatelessWidget {
  const CollaChatApp({Key? key}) : super(key: key);

  ///widget 的主要工作是提供一个 build() 方法来描述如何根据其他较低级别的 widgets 来显示自己
  @override
  Widget build(BuildContext context) {
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Application.router = router;

    ///创建了一个具有 Material Design 风格的应用
    ///监控两个数据提供者：theme，locale
    ///整个应用都会消费这两个提供者，当两个提供者的数据发生变化时，整个应用都会重绘
    ///相当于整个应用都注册了两个提供者的数据变化
    return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider.value(value: ThemeDataProvider()),
          ChangeNotifierProvider.value(value: LocaleDataProvider()),
        ],
        child: Consumer2<ThemeDataProvider, LocaleDataProvider>(builder:
            (BuildContext context, themeDataProvider, localeDataProvider,
                Widget? child) {
          return MaterialApp(
            onGenerateTitle: (context) {
              return AppLocalizations.instance.text('Welcome to CollaChat');
            },
            //title: 'Welcome to CollaChat',
            debugShowCheckedModeBanner: false,
            theme: Provider.of<ThemeDataProvider>(context).themeData,

            ///Scaffold 是 Material 库中提供的一个 widget，它提供了默认的导航栏、标题和包含主屏幕 widget 树的 body 属性
            home: Loading(title: AppLocalizations.instance.text('Loading')),
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
            // localeResolutionCallback:
            //     (Locale? locale, Iterable<Locale> supportedLocales) {
            //   if (localeDataProvider.getLocale() != null) {
            //     return localeDataProvider.getLocale();
            //   } else {
            //     Locale? _locale;
            //     if (supportedLocales.contains(locale)) {
            //       _locale = locale;
            //       Provider.of<LocaleDataProvider>(context, listen: false)
            //           .setLocale(_locale);
            //     } else {
            //       _locale =
            //           Provider.of<LocaleDataProvider>(context).getLocale();
            //     }
            //     return _locale;
            //   }
            // },
            locale: Provider.of<LocaleDataProvider>(context).getLocale(),
          );
        }));
  }
}
