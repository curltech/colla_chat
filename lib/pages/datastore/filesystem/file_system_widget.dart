import 'package:colla_chat/widgets/common/adaptive_container.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/filesystem/directory_controller.dart';
import 'package:colla_chat/widgets/filesystem/directory_widget.dart';
import 'package:colla_chat/widgets/filesystem/file_widget.dart';
import 'package:flutter/material.dart';

/// 文件管理功能主页面，带有路由回调函数
class FileSystemWidget extends StatelessWidget with TileDataMixin {
  final DirectoryController directoryController = DirectoryController();

  FileSystemWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'file_system';

  @override
  IconData get iconData => Icons.explore;

  @override
  String get title => 'FileSystem';

  @override
  Widget build(BuildContext context) {
    return AdaptiveContainer(
      main: DirectoryWidget(
        directoryController: directoryController,
      ),
      body: FileWidget(
        directoryController: directoryController,
      ),
    );
  }
}
