import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';

///flutter_background后台服务，只能用于android
///其功能是维持当前应用于后台运行，其使用了android的前台服务功能，在左上会有一个前台服务的图标
///表示有一个高优先级的前台服务在运行，不会被杀死
class AndroidBackgroundService {
  final config = FlutterBackgroundAndroidConfig(
    notificationTitle: appName,
    notificationText: AppLocalizations.t(
        'Keeping the CollaChat app running in the background'),
    notificationIcon: const AndroidResource(name: 'background_icon'),
    notificationImportance: AndroidNotificationImportance.Max,
    enableWifiLock: true,
    showBadge: true,
  );

  ///初始化并启动后台运行模式
  Future<bool> enableBackgroundExecution() async {
    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      return false;
    }
    hasPermissions = await FlutterBackground.initialize(androidConfig: config);

    if (hasPermissions) {
      final backgroundExecution =
          await FlutterBackground.enableBackgroundExecution();
      return backgroundExecution;
    }
    return false;
  }

  ///关闭后台运行模式
  Future<void> disableBackgroundExecution() async {
    bool enabled = FlutterBackground.isBackgroundExecutionEnabled;
    if (enabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }
}

final AndroidBackgroundService androidBackgroundService =
    AndroidBackgroundService();

///与AndroidBackgroundService功能相同
///其功能是维持当前应用的运行，哪怕在后台运行
class AndroidForegroundService {
  ///启动前台运行模式
  start() {
    ForegroundService().start();
  }

  ///关闭前台运行模式
  stop() {
    ForegroundService().stop();
  }
}

final AndroidForegroundService androidForegroundService =
    AndroidForegroundService();
