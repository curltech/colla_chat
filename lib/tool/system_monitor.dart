import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/material.dart';
import 'package:system_resources/system_resources.dart';
import 'package:system_status/system_status.dart';

class SystemMonitor {
  /// cpu,battery,disk,memory
  static Future<SystemStatusModel?> getMacStatus() async {
    SystemStatusMacOS systemStatus = SystemStatusMacOS();
    try {
      SystemStatusModel? systemStatusModel =
          await systemStatus.getSystemStatus();
      ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text(
                'CPU Usage - %${((systemStatusModel?.cpuUsage?.userPercentage ?? 0) + (systemStatusModel?.cpuUsage?.sysPercentage ?? 0)).toStringAsFixed(2)}'),
            subtitle: Text(
                'User: ${systemStatusModel?.cpuUsage?.userPercentage?.toStringAsFixed(2)}% | Sys: ${systemStatusModel?.cpuUsage?.sysPercentage?.toStringAsFixed(2)}% | Idle: ${systemStatusModel?.cpuUsage?.idlePercentage?.toStringAsFixed(2)}%'),
          ),
          ListTile(
            title: Text(
                'Battery - %${systemStatusModel?.batteryStatus?.currentCapacity}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Health: ${systemStatusModel?.batteryStatus?.healthString}'),
                Text(
                    'Charging: ${systemStatusModel?.batteryStatus?.isCharging == true ? 'Yes' : 'No'}'),
                Text(
                    'Charged: ${systemStatusModel?.batteryStatus?.isCharged == true ? 'Yes' : 'No'}'),
                Text(
                    'Cycle Count: ${systemStatusModel?.batteryStatus?.cycleCount}'),
                Text(
                    'Ac Powered: ${systemStatusModel?.batteryStatus?.acPowered == true ? 'Yes' : 'No'}'),
                Text(
                    'Temperature: ${systemStatusModel?.batteryStatus?.temperature?.toStringAsFixed(2)} C'),
              ],
            ),
          ),
          ListTile(
            title: const Text('Disk Space'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                    'Total: ${((systemStatusModel?.diskSpace?.totalDiskSpace ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
                Text(
                    'Free: ${((systemStatusModel?.diskSpace?.freeDiskSpace ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
                Text(
                    'Used: ${((systemStatusModel?.diskSpace?.usedDiskSpace ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
                Text(
                    'Used Percentage: ${systemStatusModel?.diskSpace?.usedPercentage?.toStringAsFixed(2)}%'),
              ],
            ),
          ),
          ListTile(
            title: Text(
                'Memory Statistics - %${systemStatusModel?.memoryStatistics?.memoryUsageRatio?.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Application Memory: ${systemStatusModel?.memoryStatistics?.applicationMemory} bytes'),
                Text(
                    'Wired Memory: ${systemStatusModel?.memoryStatistics?.wiredMemory} bytes'),
                Text(
                    'Compressed Memory: ${systemStatusModel?.memoryStatistics?.compressedMemory} bytes'),
                Text(
                    'Memory Pressure: ${systemStatusModel?.memoryStatistics?.memoryPressure}'),
              ],
            ),
          ),
        ],
      );

      return systemStatusModel;
    } catch (e) {
      logger.e('Error retrieving system status: $e');

      return null;
    }
  }

  static getSystemStatus() {
    SystemResources.cpuLoadAvg();
    SystemResources.memUsage();
    SystemResources.memUsage();
  }
}
