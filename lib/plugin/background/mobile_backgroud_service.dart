import 'dart:async';
import 'dart:ui';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

///支持android和ios，在单独线程中执行一些任务
class MobileBackgroundService {
  final FlutterBackgroundService service = FlutterBackgroundService();
  void Function()? onRepeatEvent;
  int interval = 5000;

  /// 初始化后台服务，并启动
  Future<bool> start({void Function()? onRepeatEvent}) async {
    this.onRepeatEvent = onRepeatEvent;
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // 无论应用在前台还是后台，都在独立的线程中执行
        onStart: onStart,
        autoStart: true,
        //服务是前台还是后台，前台优先级高
        isForegroundMode: true,
        notificationChannelId: 'CollaChat foreground',
        initialNotificationTitle:
            AppLocalizations.t('CollaChat foreground service'),
        initialNotificationContent:
            AppLocalizations.t('CollaChat foreground service initializing'),
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

  ///设置服务线程为前台模式，使用service.invoke将方法字符串setAsForeground数据发送给服务线程
  setAsForeground() {
    service.invoke("setAsForeground");
  }

  ///设置服务线程为后台模式
  setAsBackground() {
    service.invoke("setAsBackground");
  }

  ///判断服务线程是否正在运行
  Future<bool> isRunning() async {
    return await service.isRunning();
  }

  ///注册服务线程的方法调用事件，使用service.on服务线程接收方法字符串
  Stream<Map<String, dynamic>?> on(String method) {
    return service.on(method);
  }

  ///停止服务线程
  stop() async {
    if (await isRunning()) {
      service.invoke("stopService");
    }
  }
}

final MobileBackgroundService mobileBackgroundService =
    MobileBackgroundService();

///ios应用在后台
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

///服务线程启动，在单独的服务线程中执行的代码
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  ///注册方法事件，服务接收到方法数据调用方法设置服务的前台或者后台模式
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('update').listen((event) {
    logger.i('received method update $event');
  });

  ///注册服务的停止方法事件
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  /// 每隔5s判断是否是前台服务，如果是，设置前台的通知内容（左上角）
  Timer.periodic(Duration(milliseconds: mobileBackgroundService.interval),
      (timer) async {
    if (mobileBackgroundService.onRepeatEvent != null) {
      mobileBackgroundService.onRepeatEvent!();
    }
  });
}
