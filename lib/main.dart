import 'dart:io';
import 'dart:ui';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/notification/firebase_messaging_service.dart';
import 'package:colla_chat/plugin/notification/local_notifications_service.dart';
import 'package:colla_chat/plugin/overlay/mobile_system_alert_window.dart';
import 'package:colla_chat/plugin/pip/mobile_fl_pip_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/router_handler.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/websocket/websocket_channel.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:upgrader/upgrader.dart';
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

/// android平台下应用的系统级窗口，可以是一个按钮
@pragma("vm:entry-point")
void overlayMain() {
  if (platformParams.android) {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MobileSystemAlertOverlay(),
      ),
    );
  }
}

/// mainName must be the same as the method name
@pragma('vm:entry-point')
void pipMain() {
  runApp(ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: mobileFlPipEnabledWidget));
}

///应用主函数，使用runApp加载主应用Widget
void main(List<String> args) async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  bool loginStatus = await ServiceLocator.init();

  await FFMpegHelper.initialize();

  SystemChannels.lifecycle.setMessageHandler((msg) async {
    //logger.w('system channel switch to $msg');
    if (msg == AppLifecycleState.resumed.toString()) {
      if (platformParams.android) {
        bool? allowed = await SystemAlertWindow.checkPermissions(
            prefMode: SystemWindowPrefMode.OVERLAY);
        if (allowed == null || !allowed) {
          allowed = await SystemAlertWindow.requestPermissions(
              prefMode: SystemWindowPrefMode.OVERLAY);
        }
      }
      await websocketPool.connect();
    } else if (msg == AppLifecycleState.paused.toString() ||
        msg == AppLifecycleState.hidden.toString()) {
    } else if (msg == AppLifecycleState.inactive.toString()) {}
    return msg;
  });
  websocketPool.connect();
  _initWebView();
  await _initDesktopWindows();
  await localNotificationsService.init();
  firebaseMessagingService.init();
  FlutterForegroundTask.initCommunicationPort();

  ///加载主应用组件
  runApp(CollaChatApp(loginStatus: loginStatus));
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
      size: Size(800, 600),
      center: true,
      // backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.setMinimumSize(Size(appDataProvider.designSize.width, 600));
  }
}

///应用是一个无态的组件
class CollaChatApp extends StatelessWidget {
  final bool loginStatus;

  const CollaChatApp({super.key, required this.loginStatus});

  Widget _buildMaterialApp(BuildContext context) {
    return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider.value(value: appDataProvider),
          ChangeNotifierProvider.value(value: indexWidgetProvider),
          ChangeNotifierProvider.value(value: myself),
        ],
        child: Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(builder:
            (BuildContext context, appDataProvider, indexWidgetProvider, myself,
                Widget? child) {
          return MaterialApp(
            onGenerateTitle: (context) {
              return AppLocalizations.t('Welcome to CollaChat');
            },
            debugShowCheckedModeBanner: false,
            theme: myself.themeData,
            darkTheme: myself.darkThemeData,
            themeMode: myself.themeMode,
            home: HomeWidget(loginStatus: loginStatus),
            onGenerateRoute: Application.router.generator,
            // 初始化FlutterSmartDialog
            navigatorObservers: [FlutterSmartDialog.observer],
            builder: FlutterSmartDialog.init(
              toastBuilder: (String msg) => DialogUtil.defaultLoadingWidget(),
              loadingBuilder: (String msg) => DialogUtil.defaultLoadingWidget(),
            ),
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: supportedLocales,
            locale: myself.locale,
          );
        }));
  }

  ///widget 的主要工作是提供一个 build() 方法来描述如何根据其他较低级别的 widgets 来显示自己
  @override
  Widget build(BuildContext context) {
    return _buildMaterialApp(context);
  }
}

class HomeWidget extends StatelessWidget {
  final bool loginStatus;

  const HomeWidget({super.key, required this.loginStatus});

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
        upgrader: Upgrader(),
        child: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            appDataProvider.orientation = orientation;
            return Material(child: loginStatus ? indexView : p2pLogin);
          },
        ));
  }
}
