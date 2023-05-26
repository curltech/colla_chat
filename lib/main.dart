import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/router_handler.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:webview_win_floating/webview.dart';
import 'package:window_manager/window_manager.dart';

///全局处理证书问题
class PlatformHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

///安装客户端证书
Future<void> setCert() async {
  ByteData data =
      await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
  SecurityContext.defaultContext
      .setTrustedCertificatesBytes(data.buffer.asUint8List());
}



///应用主函数，使用runApp加载主应用Widget
void main(List<String> args) async {
  //logger.i(args.toString());
  //初始化服务类
  // 也初始化了Provider管理的全局状态数据
  //  多状态的MultiProvider(
  //       providers: [
  //         ChangeNotifierProvider(create: (context) => AppProfile()),
  //         Provider(create: (context) => AppProfile()),
  //       ],
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  ///6.x.x
  // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //   await inapp.InAppWebViewController.setWebContentsDebuggingEnabled(true);
  // }
  bool loginStatus = await ServiceLocator.init();
  if (platformParams.windows) {
    WindowsWebViewPlatform.registerWith();
  }
  if (platformParams.android) {
    inapp.AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  if (platformParams.windows || platformParams.macos || platformParams.linux) {
    windowManager.ensureInitialized();
  }

  ///加载主应用组件
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => appDataProvider),
  ], child: CollaChatApp(loginStatus: loginStatus)));
}

///应用是一个无态的组件
class CollaChatApp extends StatelessWidget {
  final bool loginStatus;

  const CollaChatApp({Key? key, required this.loginStatus}) : super(key: key);

  Widget _buildMaterialApp(BuildContext context, Widget? child) {
    return MaterialApp(
      onGenerateTitle: (context) {
        return AppLocalizations.t('Welcome to CollaChat');
      },
      //title: 'Welcome to CollaChat',
      debugShowCheckedModeBanner: false,
      theme: myself.themeData,
      darkTheme: myself.darkThemeData,
      themeMode: myself.themeMode,

      ///Scaffold 是 Material 库中提供的一个 widget，它提供了默认的导航栏、标题和包含主屏幕 widget 树的 body 属性
      home: loginStatus ? indexView : p2pLogin,
      onGenerateRoute: Application.router.generator,
      // 初始化FlutterSmartDialog
      navigatorObservers: [FlutterSmartDialog.observer],
      // builder:  (context, widget) {
      // return MediaQuery(
      //   //设置全局的文字的textScaleFactor为1.0，文字不再随系统设置改变
      //   data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      //   child: widget,
      // );
      builder: FlutterSmartDialog.init(
        //default toast widget
        toastBuilder: (String msg) => DialogUtil.defaultLoadingWidget(),
        //default loading widget
        loadingBuilder: (String msg) => DialogUtil.defaultLoadingWidget(),
      ),
      // themeMode: StringUtil.enumFromString(
      //     ThemeMode.values, appDataProvider.brightness),
      // AppLocalizations.localizationsDelegates,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
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
      locale: myself.locale,
    );
  }

  ///widget 的主要工作是提供一个 build() 方法来描述如何根据其他较低级别的 widgets 来显示自己
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider.value(value: appDataProvider),
          ChangeNotifierProvider.value(value: indexWidgetProvider),
          ChangeNotifierProvider.value(value: myself),
        ],
        child: Consumer<Myself>(
            builder: (BuildContext context, myself, Widget? child) {
          return ScreenUtilInit(
              designSize: appDataProvider.designSize,
              minTextAdapt: true,
              splitScreenMode: true,
              builder: _buildMaterialApp);
        }));
  }
}
