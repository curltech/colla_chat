import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

///支持android和ios，在单独线程中执行一些前台任务
///只要前台任务运行，则应用不会被关闭
class MobileForegroundTask {
  ///接收数据端口，接收前台服务任务发送来的数据
  ReceivePort? receivePort;
  AndroidNotificationOptions androidNotificationOptions =
      AndroidNotificationOptions(
    channelId: 'fCollaChat foreground',
    channelName: 'CollaChat foreground service',
    channelDescription: AppLocalizations.t(
        'This notification appears when the CollaChat foreground service is running.'),
    channelImportance: NotificationChannelImportance.HIGH,
    priority: NotificationPriority.MAX,
    iconData: const NotificationIconData(
      resType: ResourceType.mipmap,
      resPrefix: ResourcePrefix.ic,
      name: 'launcher',
    ),
    buttons: [
      const NotificationButton(id: 'sendButton', text: 'Send'),
      const NotificationButton(id: 'testButton', text: 'Test'),
    ],
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

  init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
      foregroundTaskOptions: foregroundTaskOptions,
    );
  }

  Future<void> requestPermissionForAndroid() async {
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

  Future<bool> start() async {
    /// 存储数据到前台任务线程
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    /// 启动前台任务前注册接收端口
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = registerReceivePort(receivePort);
    if (!isRegistered) {
      logger.e('Failed to register receivePort!');
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        callback: onStart,
      );
    }
  }

  bool registerReceivePort(ReceivePort? newReceivePort) {
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

  Future<bool> updateService() {
    return FlutterForegroundTask.updateService(
      foregroundTaskOptions: foregroundTaskOptions,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      callback: onStart,
    );
  }

  Future<bool> stop() {
    return FlutterForegroundTask.stopService();
  }

  ///创建WillStartForegroundTask组件，MaterialApp的home，用于包裹Scaffold
  ///当应用最小化或者终止的时候，这个组件能够启动前台服务
  WillStartForegroundTask willStartForegroundTask({
    Key? key,
    Future<bool> Function()? onWillStart,
    AndroidNotificationOptions? androidNotificationOptions,
    IOSNotificationOptions? iosNotificationOptions,
    ForegroundTaskOptions? foregroundTaskOptions,
    String? notificationTitle,
    String? notificationText,
    Function? callback,
    void Function(dynamic)? onData,
    required Widget child,
  }) {
    onWillStart ??= () async {
      return true;
    };
    androidNotificationOptions ??= this.androidNotificationOptions;
    iosNotificationOptions ??= this.iosNotificationOptions;
    foregroundTaskOptions ??= this.foregroundTaskOptions;
    notificationTitle ??= this.notificationTitle;
    notificationText ??= this.notificationText;
    callback ??= onStart;
    onData ??= this.onData;
    return WillStartForegroundTask(
      onWillStart: onWillStart,
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
      foregroundTaskOptions: foregroundTaskOptions,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      callback: callback,
      onData: onData,
      child: child,
    );
  }

  ///前台服务任务发来数据事件
  void onData(dynamic data) async {
    logger.i('received foreground service data:$data');
  }

  ///创建WillForegroundTask组件，用于包裹Scaffold，使用前需要先调用初始化init方法
  ///当前台服务运行时，防止应用被关闭
  WithForegroundTask withForegroundTask({Key? key, required Widget child}) {
    return WithForegroundTask(
      key: key,
      child: child,
    );
  }

  minimizeApp() {
    FlutterForegroundTask.minimizeApp();
  }

  launchApp([String? route]) {
    FlutterForegroundTask.launchApp(route);
  }

  wakeUpScreen() {
    FlutterForegroundTask.wakeUpScreen();
  }

  Future<bool> get isAppOnForeground async {
    return await FlutterForegroundTask.isAppOnForeground;
  }

  setOnLockScreenVisibility(bool isVisible) {
    FlutterForegroundTask.setOnLockScreenVisibility(isVisible);
  }
}

final MobileForegroundTask mobileForegroundTask = MobileForegroundTask();

///实际的任务处理器
class MobileForegroundTaskHandler extends TaskHandler {
  SendPort? _sendPort;

  /// 任务开始的时候调用
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // You can use the getData function to get the stored data.
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
  }

  // 周期任务调用 [ForegroundTaskOptions].
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // 发送数据给主线程
    sendPort?.send(timestamp);
  }

  /// 通知按钮被按的时候调用，android平台
  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {}

  /// 通知按钮被按的时候调用，android平台
  @override
  void onNotificationButtonPressed(String id) {}

  /// 通知被按的时候调用，android平台
  /// "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  /// this function to be called.
  @override
  void onNotificationPressed() {
    // 应用退出的时候重启应用，并且发送数据到应用
    FlutterForegroundTask.launchApp();
    _sendPort?.send('onNotificationPressed');
  }
}

///服务线程启动，在单独的服务线程中执行的代码
@pragma('vm:entry-point')
void onStart() async {
  FlutterForegroundTask.setTaskHandler(MobileForegroundTaskHandler());
}
