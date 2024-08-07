import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

///支持android和ios，在单独线程中执行一些前台任务
///只要前台任务运行，则应用不会被关闭
/// iOS有一些限制：app被强制终止时，设备重启时，任务不会工作，onRepeatEvent可能不能正常工作
class MobileForegroundTask {
  void Function()? onRepeatEvent;

  ///接收数据端口，接收前台服务任务发送来的数据
  ReceivePort? receivePort;
  AndroidNotificationOptions androidNotificationOptions =
      AndroidNotificationOptions(
    channelId: 'CollaChat foreground',
    channelName: 'CollaChat foreground service',
    channelDescription:
        AppLocalizations.t('CollaChat foreground service is running'),
    channelImportance: NotificationChannelImportance.HIGH,
    priority: NotificationPriority.MAX,
  );
  IOSNotificationOptions iosNotificationOptions = const IOSNotificationOptions(
    showNotification: true,
    playSound: false,
  );
  ForegroundTaskOptions foregroundTaskOptions = const ForegroundTaskOptions(
    interval: 5000,
    isOnceEvent: false,
    autoRunOnBoot: true,
    allowWakeLock: true,
    allowWifiLock: true,
  );
  String notificationTitle =
      AppLocalizations.t('CollaChat foreground Service is running');
  String notificationText = AppLocalizations.t('Tap to return to the app');

  /// 初始化前台任务
  _init() async {
    await _requestPermissionForAndroid();
    FlutterForegroundTask.init(
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
      foregroundTaskOptions: foregroundTaskOptions,
    );
  }

  Future<void> _requestPermissionForAndroid() async {
    if (!platformParams.android) {
      return;
    }

    // 必须有"android.permission.SYSTEM_ALERT_WINDOW"权限
    // onNotificationPressed方法将被调用
    if (!await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    // Android 12或者更高，前台服务有些限制
    // 设备重启或者崩溃的时候重启服务，需要android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS权限
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Android 13或者更高，前台服务通知需要notification权限
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  /// 手工启动任务
  Future<Object> start({void Function()? onRepeatEvent}) async {
    this.onRepeatEvent = onRepeatEvent;
    await _init();

    /// 启动前台任务前注册接收端口
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      logger.e('Failed to register receivePort!');
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      print('FlutterForegroundTask restartService');
      return await FlutterForegroundTask.restartService();
    } else {
      print('FlutterForegroundTask startService');
      return FlutterForegroundTask.startService(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        callback: onStart,
      );
    }
  }

  /// 注册接收端口
  bool _registerReceivePort(ReceivePort? newReceivePort) {
    newReceivePort ??= FlutterForegroundTask.receivePort;
    if (newReceivePort == receivePort) {
      return false;
    }

    receivePort?.close();
    receivePort = null;

    receivePort = newReceivePort;
    receivePort?.listen((data) {
      onData(data);
    });

    return receivePort != null;
  }

  /// 更新服务任务参数
  Future<ServiceRequestResult> updateService() {
    return FlutterForegroundTask.updateService(
      foregroundTaskOptions: foregroundTaskOptions,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      callback: onStart,
    );
  }

  /// 停止任务
  Future<ServiceRequestResult> stop() {
    receivePort?.close();
    receivePort = null;
    return FlutterForegroundTask.stopService();
  }

  Future<bool> get isRunningService async {
    return await FlutterForegroundTask.isRunningService;
  }

  ///前台服务任务发来数据事件
  void onData(dynamic data) async {
    print('received foreground service data:$data');
  }

  ///创建WillForegroundTask组件，用于包裹Scaffold，使用前需要先调用初始化init方法
  ///当前台服务运行时，防止应用被关闭，这是手工启动任务的时候使用
  WithForegroundTask withForegroundTask({Key? key, required Widget child}) {
    return WithForegroundTask(
      key: key,
      child: child,
    );
  }

  ///最小化app
  minimizeApp() {
    FlutterForegroundTask.minimizeApp();
  }

  ///如果app没有关闭，启动app
  launchApp([String? route]) {
    FlutterForegroundTask.launchApp(route);
  }

  ///屏幕关闭的时候打开屏幕
  wakeUpScreen() {
    FlutterForegroundTask.wakeUpScreen();
  }

  /// 应用是否在前台
  Future<bool> get isAppOnForeground async {
    return await FlutterForegroundTask.isAppOnForeground;
  }

  ///切换锁定屏幕的可见性
  setOnLockScreenVisibility(bool isVisible) {
    FlutterForegroundTask.setOnLockScreenVisibility(isVisible);
  }

  /// 从SharedPreferences获取数据
  Future<T?> getData<T>(String key) {
    return FlutterForegroundTask.getData(key: key);
  }

  /// 保存数据到SharedPreferences
  saveData(String key, Object value) async {
    await FlutterForegroundTask.saveData(key: key, value: value);
  }
}

final MobileForegroundTask mobileForegroundTask = MobileForegroundTask();

/// 实际的前台任务处理器
class MobileForegroundTaskHandler extends TaskHandler {
  //启动后的发送端口
  SendPort? _sendPort;

  /// 任务开始的时候调用
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    print('MobileForegroundTask started');
    Timer.periodic(const Duration(seconds: 1), (timer) {
      print('MobileForegroundTask periodic running');
    });
  }

  // 周期任务调用 [ForegroundTaskOptions].
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    print('onRepeatEvent started');
    if (mobileForegroundTask.onRepeatEvent != null) {
      mobileForegroundTask.onRepeatEvent!();
    }
  }

  /// 通知按钮被按的时候调用，android平台
  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('MobileForegroundTask onDestroy');
  }

  /// 通知按钮被按的时候调用，android平台
  @override
  void onNotificationButtonPressed(String id) {
    print('MobileForegroundTask onNotificationButtonPressed');
  }

  /// 通知被按的时候调用，android平台
  /// 必须有"android.permission.SYSTEM_ALERT_WINDOW"权限
  @override
  void onNotificationPressed() {
    print('MobileForegroundTask onNotificationPressed');
    // 应用退出的时候重启应用，并且发送数据到应用
    FlutterForegroundTask.launchApp();
  }
}

///服务线程启动，在单独的服务线程中执行的代码
@pragma('vm:entry-point')
void onStart() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(MobileForegroundTaskHandler());
}
