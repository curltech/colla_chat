import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 日志显示
class LoggerConsoleView extends StatefulWidget with TileDataMixin {
  const LoggerConsoleView({super.key});

  @override
  State<StatefulWidget> createState() => _LoggerConsoleViewState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'logger';

  @override
  IconData get iconData => Icons.terminal;

  @override
  String get title => 'Logger console';
}

class _LoggerConsoleViewState extends State<LoggerConsoleView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: const LoggerConsoleWidget());
  }

  @override
  void dispose() {
    super.dispose();
  }
}
