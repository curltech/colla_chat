import 'dart:io';
import 'dart:ui';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/plugin/notification/firebase_messaging_service.dart';
import 'package:colla_chat/plugin/notification/local_notifications_service.dart';
import 'package:colla_chat/plugin/overlay/android_overlay_window_util.dart';
import 'package:colla_chat/plugin/overlay/chat_message_overlay.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/router_handler.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:upgrader/upgrader.dart';
import 'package:webview_win_floating/webview.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

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

/// android平台下应用的系统级窗口，可以是一个按钮
@pragma("vm:entry-point")
void overlayMain() {
  if (platformParams.android) {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ChatMessageOverlay(),
      ),
    );
  }
}

///应用主函数，使用runApp加载主应用Widget
void main(List<String> args) async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  bool loginStatus = await ServiceLocator.init();

  SystemChannels.lifecycle.setMessageHandler((msg) async {
    logger.w('system channel switch to $msg');
    if (msg == AppLifecycleState.resumed.toString()) {
      bool? allowed = await AndroidOverlayWindowUtil.isPermissionGranted();
      if (!allowed) {
        allowed = await AndroidOverlayWindowUtil.requestPermission();
      }
      await websocketPool.connect();
    } else if (msg == AppLifecycleState.paused.toString() ||
        msg == AppLifecycleState.hidden.toString()) {
      localNotificationsService.showNotification(
          'CollaChat', AppLocalizations.t('CollaChat App inactive'));
      // if (platformParams.android) {
      //   if (!await AndroidOverlayWindowUtil.isActive()) {
      //     bool allowed = await AndroidOverlayWindowUtil.isPermissionGranted();
      //     if (allowed) {
      //       await AndroidOverlayWindowUtil.showOverlay();
      //     }
      //   }
      // }
    } else if (msg == AppLifecycleState.inactive.toString()) {}
    return msg;
  });
  websocketPool.connect();
  _initWebView();
  await _initDesktopWindows();
  await localNotificationsService.init();
  firebaseMessagingService.init();

  ///加载主应用组件
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => appDataProvider),
  ], child: CollaChatApp(loginStatus: loginStatus)));
}

///初始化内置浏览器，webview_flutter和inapp两个实现
void _initWebView() {
  if (platformParams.windows) {
    WindowsWebViewPlatform.registerWith();
  }
  //对android平台一些特定初始化设置
  int inAppWebViewVersion = 6;
  if (inAppWebViewVersion == 6) {
    ///6.x.x
    if (platformParams.android) {
      inapp.InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  }
  if (inAppWebViewVersion == 5) {
    ///5.x.x
    if (platformParams.android) {
      inapp.AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  }
}

/// default, we use the communication audio mode,
/// 使用媒体播放模式，media playback
Future<void> initializeAndroidAudioSettings() async {
  await webrtc.WebRTC.initialize(options: {
    'androidAudioConfiguration': webrtc.AndroidAudioConfiguration.media.toMap()
  });
  webrtc.Helper.setAndroidAudioConfiguration(
      webrtc.AndroidAudioConfiguration.media);
}

///初始化桌面平台的窗口管理
Future<void> _initDesktopWindows() async {
  if (platformParams.desktop) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      title: appName,
      size: Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.setMinimumSize(const Size(398.0, 768.0));
  }
}

///应用是一个无态的组件
class CollaChatApp extends StatefulWidget {
  final bool loginStatus;

  const CollaChatApp({super.key, required this.loginStatus});

  @override
  State<StatefulWidget> createState() {
    return _CollaChatAppState();
  }
}

class _CollaChatAppState extends State<CollaChatApp> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildMaterialApp(BuildContext context, Widget? child) {
    return MaterialApp(
      onGenerateTitle: (context) {
        return AppLocalizations.t('Welcome to CollaChat');
      },
      debugShowCheckedModeBanner: false,
      theme: myself.themeData,
      darkTheme: myself.darkThemeData,
      themeMode: myself.themeMode,

      ///Scaffold 是 Material 库中提供的一个 widget，它提供了默认的导航栏、标题和包含主屏幕 widget 树的 body 属性
      home: UpgradeAlert(
          upgrader: Upgrader(),
          child: widget.loginStatus ? indexView : p2pLogin),
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

  @override
  void dispose() {
    super.dispose();
  }
}
