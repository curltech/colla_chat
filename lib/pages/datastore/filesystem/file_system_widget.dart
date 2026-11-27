import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/filesystem/directory_controller.dart';
import 'package:colla_chat/widgets/filesystem/directory_widget.dart';
import 'package:colla_chat/widgets/filesystem/file_node.dart';
import 'package:colla_chat/widgets/filesystem/file_widget.dart';
import 'package:flutter/material.dart';

/// 文件管理功能主页面，带有路由回调函数
class FileSystemWidget extends StatelessWidget with DataTileMixin {
  final DirectoryController directoryController = DirectoryController();
  late final DirectoryWidget main = DirectoryWidget(
    directoryController: directoryController,
  );

  late final FileWidget body = FileWidget(
    directoryController: directoryController,
  );

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
    return ListenableBuilder(
      listenable: directoryController.currentNode,
      builder: (BuildContext context, Widget? child) {
        String? path;
        Folder? folder =
            directoryController.currentNode.value?.value as Folder?;
        if (folder != null) {
          path = folder.directory.path;
        } else {
          path = title;
        }
        return AppBarAdaptiveView(
          title: path,
          helpPath: routeName,
          withLeading: true,
          main: main,
          body: body,
        );
      },
    );
  }
}
