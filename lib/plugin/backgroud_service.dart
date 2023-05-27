import 'dart:async';
import 'dart:ui';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/ping.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

///flutter_background背景服务实现，android
///可以用于实现在后台接收消息
class AndroidBackgroundService {
  final config = FlutterBackgroundAndroidConfig(
    notificationTitle: 'CollaChat',
    notificationText: AppLocalizations.t(
        'Keeping the CollaChat app running in the background'),
    notificationIcon: const AndroidResource(name: 'background_icon'),
    notificationImportance: AndroidNotificationImportance.Default,
    enableWifiLock: true,
    showBadge: true,
  );
  Timer? _heartTimer;

  ///请求权限
  Future<bool> requestPermission() async {
    var hasPermissions = await FlutterBackground.hasPermissions;
    // if (!hasPermissions) {
    //   hasPermissions = await showDialog(
    //       context: context,
    //       builder: (context) {
    //         return AlertDialog(
    //             title: Text(AppLocalizations.t('Permissions needed')),
    //             content: Text(AppLocalizations.t(
    //                 'Shortly the OS will ask you for permission to execute this app in the background. This is required in order to receive chat messages when the app is not in the foreground.')),
    //             actions: [
    //               TextButton(
    //                 onPressed: () => Navigator.pop(context, true),
    //                 child: Text(AppLocalizations.t('Ok')),
    //               ),
    //             ]);
    //       });
    // }
    return hasPermissions;
  }

  ///初始化并启动后台服务
  Future<bool> enableBackgroundExecution({bool heartTimer = false}) async {
    bool hasPermissions = await requestPermission();
    if (hasPermissions) {}
    hasPermissions = await FlutterBackground.initialize(androidConfig: config);

    if (hasPermissions) {
      final backgroundExecution =
          await FlutterBackground.enableBackgroundExecution();
      if (backgroundExecution && heartTimer) {
        _heartTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          pingAction.ping({'content': 'hello'});
          logger.i('pingAction ping hello');
        });
      }

      return backgroundExecution;
    }
    return false;
  }

  ///关闭后台服务
  Future<void> disableBackgroundExecution() async {
    bool enabled = FlutterBackground.isBackgroundExecutionEnabled;
    if (enabled) {
      await FlutterBackground.disableBackgroundExecution();
      if (_heartTimer != null) {
        _heartTimer!.cancel();
        _heartTimer = null;
      }
    }
  }
}

final AndroidBackgroundService androidBackgroundService =
    AndroidBackgroundService();

///后台服务
///UI和Service之间的通讯用invoke()发送数据和on(String method)接收数据.
class BackgroundService {
  final FlutterBackgroundService service = FlutterBackgroundService();

  ///初始化后台服务，并启动
  Future<bool> start() async {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will be executed when app is in foreground or background in separated isolate
        onStart: onStart,
        // auto start service
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'CollaChat foreground',
        initialNotificationTitle: 'CollaChat foreground service',
        initialNotificationContent: 'CollaChat foreground service initializing',
        foregroundServiceNotificationId: 8888,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: true,
        // this will be executed when app is in foreground in separated isolate
        onForeground: onStart,
        // you have to enable background fetch capability on xcode project
        onBackground: onIosBackground,
      ),
    );

    return await service.startService();
  }

  setAsForeground() {
    service.invoke("setAsForeground");
  }

  setAsBackground() {
    service.invoke("setAsBackground");
  }

  Future<bool> isRunning() async {
    return await service.isRunning();
  }

  Stream<Map<String, dynamic>?> on(String method) {
    return service.on(method);
  }

  stop() async {
    if (await isRunning()) {
      service.invoke("stopService");
    }
  }
}

final BackgroundService backgroundService = BackgroundService();

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  logger.i('ios background:${DateTime.now().toIso8601String()}');

  return true;
}

///应用到前景
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  logger.i('onStart:${DateTime.now().toIso8601String()}');

  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "CollaChat Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    /// you can see this log in logcat
    logger.i('CollaChat BackGround Service: ${DateTime.now()}');

    // test using external plugin
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (platformParams.android) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (platformParams.ios) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}
