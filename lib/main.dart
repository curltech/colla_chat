import 'package:colla_chat/pages/loading.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/locale_data.dart';
import 'package:colla_chat/provider/theme_data.dart';
import 'package:colla_chat/routers/application.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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
    return MaterialApp(
      title: 'Welcome to CollaChat',
      debugShowCheckedModeBanner: false,
      // 取值方法Provider.of<AppProfile>(context)
      //  当ChangeNotifier 发生变化的时候会调用 builder 这个函数
      // Consumer<AppProfile>(
      //   builder: (context, appProfile, child) {
      //     return Text("Total price: ${appProfile.themeData}");
      //   },
      // );
      theme: Provider.of<ThemeDataProvider>(context).themeData,

      ///Scaffold 是 Material 库中提供的一个 widget，它提供了默认的导航栏、标题和包含主屏幕 widget 树的 body 属性
      home: Loading(title: 'Flutter Swiper'),
      onGenerateRoute: Application.router.generator,

      // AppLocalizations.localizationsDelegates,
      localizationsDelegates: const [
        // AppLocalizations.of(context)!.helloWorld
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // AppLocalizations.supportedLocales,
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
        Locale('zh', 'TW'),
        Locale('ja', 'JP'),
        Locale('ko', 'KR'),
      ],
      locale: Provider.of<LocaleDataProvider>(context).locale,
    );
  }
}
