import 'dart:async';
import 'dart:ui';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

///支持android和ios，在单独线程中执行一些任务
class MobileBackgroundService {
  final FlutterBackgroundService service = FlutterBackgroundService();

  ///初始化后台服务，并启动
  Future<bool> start() async {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // 无论应用在前台还是后台，都在独立的线程中执行
        onStart: onStart,
        autoStart: true,
        //服务是前台还是后台，前台优先级高
        isForegroundMode: true,
        notificationChannelId: 'CollaChat foreground',
        initialNotificationTitle: 'CollaChat foreground service',
        initialNotificationContent: 'CollaChat foreground service initializing',
        foregroundServiceNotificationId: 8888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        // 无论应用在前台，在独立的线程中执行
        onForeground: onStart,
        // 应用在后台，在独立的线程中执行，background fetch capability
        // ios每隔15分钟调用一次
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

final MobileBackgroundService backgroundService = MobileBackgroundService();

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  logger.i('ios background:${DateTime.now().toIso8601String()}');

  return true;
}

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
