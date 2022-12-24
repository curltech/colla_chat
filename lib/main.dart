import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/routers/router_handler.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
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

///启动背景服务
Future<bool> startForegroundService() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'CollaChat',
    notificationText: '',
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  return FlutterBackground.enableBackgroundExecution();
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
  WidgetsFlutterBinding.ensureInitialized();
  if (platformParams.windows || platformParams.macos || platformParams.linux) {
    await windowManager.ensureInitialized();
  }
  if (Platform.isAndroid) {
    await inapp.AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  ///6.x.x
  // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //   await inapp.InAppWebViewController.setWebContentsDebuggingEnabled(true);
  // }
  ServiceLocator.init().then((bool loginStatus) {
    ///加载主应用组件
    runApp(MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => appDataProvider),
    ], child: CollaChatApp(loginStatus: loginStatus)));
  });
}

///应用是一个无态的组件
class CollaChatApp extends StatelessWidget {
  final bool loginStatus;

  const CollaChatApp({Key? key, required this.loginStatus}) : super(key: key);

  ///widget 的主要工作是提供一个 build() 方法来描述如何根据其他较低级别的 widgets 来显示自己
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider.value(value: appDataProvider),
          ChangeNotifierProvider.value(value: indexWidgetProvider),
        ],
        child: Consumer<AppDataProvider>(
            builder: (BuildContext context, appDataProvider, Widget? child) {
          return MaterialApp(
            onGenerateTitle: (context) {
              return AppLocalizations.t('Welcome to CollaChat');
            },
            //title: 'Welcome to CollaChat',
            debugShowCheckedModeBanner: false,
            theme: Provider.of<AppDataProvider>(context).themeData,

            ///Scaffold 是 Material 库中提供的一个 widget，它提供了默认的导航栏、标题和包含主屏幕 widget 树的 body 属性
            home: loginStatus ? indexView : p2pLogin,
            onGenerateRoute: Application.router.generator,
            // 初始化FlutterSmartDialog
            navigatorObservers: [FlutterSmartDialog.observer],
            builder: FlutterSmartDialog.init(
              //default toast widget
              toastBuilder: (String msg) =>
                  SmartDialogUtil.defaultLoadingWidget(),
              //default loading widget
              loadingBuilder: (String msg) =>
                  SmartDialogUtil.defaultLoadingWidget(),
            ),

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
            locale: Provider.of<AppDataProvider>(context).getLocale(),
          );
        }));
  }
}
