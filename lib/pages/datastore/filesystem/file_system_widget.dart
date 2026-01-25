import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/adaptive_container.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/filesystem/directory_controller.dart';
import 'package:colla_chat/widgets/filesystem/directory_widget.dart';
import 'package:colla_chat/widgets/filesystem/file_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:colla_chat/widgets/filesystem/file_node.dart';

/// 文件管理功能主页面，带有路由回调函数
class FileSystemWidget extends StatelessWidget with TileDataMixin {
  final DirectoryController directoryController = DirectoryController();
  late final DirectoryWidget main = DirectoryWidget(
    directoryController: directoryController,
  );
  AdaptiveContainerController? controller;

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
    var provider = Consumer3<AppDataProvider, IndexWidgetProvider, Myself>(
        builder:
            (context, appDataProvider, indexWidgetProvider, myself, child) {
      ContainerType containerType = ContainerType.carousel;
      if (appDataProvider.landscape) {
        if (appDataProvider.bodyWidth == 0) {
          containerType = ContainerType.resizeable;
        }
      }
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
          controller = AdaptiveContainerController(
            containerType: containerType,
            pixels: 380,
          );
          return AppBarView(
              title: path,
              helpPath: routeName,
              withLeading: true,
              rightWidgets: [
                IconButton(
                    onPressed: () {
                      controller?.toggle();
                    },
                    icon: Icon(Icons.vertical_split_outlined))
              ],
              child: AdaptiveContainer(
                controller: controller!,
                main: main,
                body: body,
              ));
        },
      );
    });
    return provider;
  }
}
