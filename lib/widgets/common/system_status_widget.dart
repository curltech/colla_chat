import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:get/get.dart';
import 'package:system_resources/system_resources.dart';
import 'package:system_status/system_status.dart';

import 'package:colla_chat/plugin/talker_logger.dart';

class SystemStatusWidget extends StatelessWidget with TileDataMixin {
  final Rx<Battery?> battery = Rx<Battery?>(null);

  final Rx<BatteryState?> batteryState = Rx<BatteryState?>(null);

  final Rx<SystemStatusModel?> systemStatusModel = Rx<SystemStatusModel?>(null);

  SystemStatusWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'system_status';

  @override
  IconData get iconData => Icons.system_security_update_good_outlined;

  @override
  String get title => 'System status';

  _init() async {
    if (platformParams.macos) {
      try {
        SystemStatusMacOS systemStatus = SystemStatusMacOS();
        systemStatusModel.value = await systemStatus.getSystemStatus();
      } catch (e) {
        logger.e('getSystemStatus failure:$e');
      }
    }
    battery.value = Battery();
    battery.value?.onBatteryStateChanged.listen((BatteryState state) {
      batteryState.value = state;
    });
    try {
      await SystemResources.init();
    } catch (e) {
      logger.e('SystemResources init failure:$e');
    }
  }

  Widget _buildMacSystemMonitorWidget() {
    return Obx(() {
      SystemStatusModel? systemStatusModel = this.systemStatusModel.value;
      List<TileData> cpuTiles = [
        TileData(
            title: 'CPU usage userPercentage',
            titleTail:
                '${systemStatusModel?.cpuUsage?.userPercentage?.toStringAsFixed(2)}%'),
        TileData(
            title: 'CPU usage sysPercentage',
            titleTail:
                '${systemStatusModel?.cpuUsage?.sysPercentage?.toStringAsFixed(2)}%'),
        TileData(
            title: 'CPU usage idlePercentage',
            titleTail:
                '${systemStatusModel?.cpuUsage?.idlePercentage?.toStringAsFixed(2)}%'),
      ];
      List<TileData> batteryTiles = [
        TileData(
            title: 'Battery',
            titleTail: '${systemStatusModel?.batteryStatus?.currentCapacity}%'),
        TileData(
            title: 'Health',
            titleTail: '${systemStatusModel?.batteryStatus?.healthString}'),
        TileData(
            title: 'Charging',
            titleTail: systemStatusModel?.batteryStatus?.isCharging == true
                ? 'Yes'
                : 'No'),
        TileData(
            title: 'Charged',
            titleTail: systemStatusModel?.batteryStatus?.isCharged == true
                ? 'Yes'
                : 'No'),
        TileData(
            title: 'Cycle Count',
            titleTail: '${systemStatusModel?.batteryStatus?.cycleCount}'),
        TileData(
            title: 'Ac Powered',
            titleTail: systemStatusModel?.batteryStatus?.acPowered == true
                ? 'Yes'
                : 'No'),
        TileData(
            title: 'Temperature',
            titleTail:
                '${systemStatusModel?.batteryStatus?.temperature?.toStringAsFixed(2)} C'),
      ];
      List<TileData> diskSpaceTiles = [
        TileData(
            title: 'Total',
            titleTail:
                '${((systemStatusModel?.diskSpace?.totalDiskSpace ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
        TileData(
            title: 'Free',
            titleTail:
                '${((systemStatusModel?.diskSpace?.freeDiskSpace ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
        TileData(
            title: 'Used',
            titleTail:
                '${((systemStatusModel?.diskSpace?.usedDiskSpace ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
        TileData(
            title: 'Used Percentage',
            titleTail:
                '${systemStatusModel?.diskSpace?.usedPercentage?.toStringAsFixed(2)}%'),
      ];
      List<TileData> memoryTiles = [
        TileData(
            title: 'Memory Statistics',
            titleTail:
                '%${systemStatusModel?.memoryStatistics?.memoryUsageRatio?.toStringAsFixed(2)}'),
        TileData(
            title: 'Application Memory',
            titleTail:
                '${systemStatusModel?.memoryStatistics?.applicationMemory} bytes'),
        TileData(
            title: 'Wired Memory',
            titleTail:
                '${systemStatusModel?.memoryStatistics?.wiredMemory} bytes'),
        TileData(
            title: 'Compressed Memory',
            titleTail:
                '${systemStatusModel?.memoryStatistics?.compressedMemory} bytes'),
        TileData(
            title: 'Memory Pressure',
            titleTail:
                ' ${systemStatusModel?.memoryStatistics?.memoryPressure}'),
      ];

      Map<TileData, List<TileData>> tileData = {
        TileData(
          title: 'CPU status',
          selected: true,
        ): cpuTiles,
        TileData(
          title: 'Battery status',
          selected: true,
        ): batteryTiles,
        TileData(
          title: 'DiskSpace status',
          selected: true,
        ): diskSpaceTiles,
        TileData(
          title: 'Memory status',
          selected: true,
        ): memoryTiles,
      };

      return GroupDataListView(
        tileData: tileData,
      );
    });
  }

  Widget _buildNonMacSystemMonitorWidget() {
    return Obx(() {
      List<TileData> batteryTiles = [
        TileData(
            title: 'batteryState', titleTail: '${batteryState.value?.name}'),
        TileData(
            title: 'batteryLevel', titleTail: '${battery.value?.batteryLevel}'),
        TileData(
            title: 'batteryLevel',
            titleTail: '${battery.value?.isInBatterySaveMode}'),
      ];

      List<TileData> systemResourceTiles = [
        TileData(
            title: 'cpuLoadAvg', titleTail: '${SystemResources.cpuLoadAvg()}'),
        TileData(title: 'memUsage', titleTail: '${SystemResources.memUsage()}'),
      ];

      Map<TileData, List<TileData>> tileData = {
        TileData(
          title: 'System status',
          selected: true,
        ): systemResourceTiles,
        TileData(
          title: 'Battery status',
          selected: true,
        ): batteryTiles,
      };

      return GroupDataListView(
        tileData: tileData,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: withLeading,
        child: platformParams.macos
            ? _buildMacSystemMonitorWidget()
            : _buildNonMacSystemMonitorWidget());
  }
}
