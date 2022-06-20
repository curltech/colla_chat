import 'package:colla_chat/pages/chat/login/p2p_login.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/servicelocator.dart';
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
      ChangeNotifierProvider(create: (context) => AppDataProvider.instance),
    ], child: CollaChatApp()));
  });
}

///应用是一个无态的组件
class CollaChatApp extends StatelessWidget {
  const CollaChatApp({Key? key}) : super(key: key);

  ///widget 的主要工作是提供一个 build() 方法来描述如何根据其他较低级别的 widgets 来显示自己
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider.value(value: appDataProvider),
        ],
        child: Consumer<AppDataProvider>(
            builder: (BuildContext context, appDataProvider, Widget? child) {
          return MaterialApp(
            onGenerateTitle: (context) {
              return AppLocalizations.instance.text('Welcome to CollaChat');
            },
            //title: 'Welcome to CollaChat',
            debugShowCheckedModeBanner: false,
            theme: Provider.of<AppDataProvider>(context).themeData,

            ///Scaffold 是 Material 库中提供的一个 widget，它提供了默认的导航栏、标题和包含主屏幕 widget 树的 body 属性
            home: const P2pLogin(),
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
            locale: Provider.of<AppDataProvider>(context).getLocale(),
          );
        }));
  }
}
