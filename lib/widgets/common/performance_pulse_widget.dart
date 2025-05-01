import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_performance_pulse/flutter_performance_pulse.dart';

class PerformancePulseWidget extends StatelessWidget with TileDataMixin {
  PerformancePulseWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'performance_pulse';

  @override
  IconData get iconData => Icons.insert_chart;

  @override
  String get title => 'Performance pulse';

  _init() async {
    await PerformanceMonitor.instance.initialize(
      config: MonitorConfig(
        showMemory: true,
        showLogs: true,
        trackStartup: true,
        interceptNetwork: true,

        // Performance thresholds
        fpsWarningThreshold: 45,
        memoryWarningThreshold: 500 * 1024 * 1024,
        // 500MB
        diskWarningThreshold: 85.0,
        // Warn at 85% disk usage

        // Feature toggles
        enableNetworkMonitoring: true,
        enableBatteryMonitoring: true,
        enableDeviceInfo: true,
        enableDiskMonitoring: true,

        // Logging options
        logLevel: LogLevel.verbose,
        exportLogs: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: withLeading,
        child: PerformanceDashboard(theme:DashboardTheme.light(),));
  }
}
