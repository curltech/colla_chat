import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 日志显示
class LoggerConsoleView extends StatelessWidget with TileDataMixin {
  const LoggerConsoleView({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'logger';

  @override
  IconData get iconData => Icons.terminal;

  @override
  String get title => 'Logger console';

  

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: title,
        helpPath: routeName,
        child: const TalkerLoggerScreenWidget());
  }
}
