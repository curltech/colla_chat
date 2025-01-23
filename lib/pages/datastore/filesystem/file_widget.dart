import 'dart:io' as io;

import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_system_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mimecon/mimecon.dart';

/// 文件管理功能主页面，带有路由回调函数
class FileWidget extends StatelessWidget with TileDataMixin {
  FileWidget({super.key}) {
    fileSystemController.current.addListener(() {
      _buildFiles();
    });
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'file';

  @override
  IconData get iconData => Icons.explore;

  @override
  String get title => 'File';

  final DataListController<File> fileController = DataListController<File>();

  _buildFiles() {
    Folder? folder = fileSystemController.current.value;
    io.Directory? directory = folder?.directory;
    if (directory == null) {
      fileController.replaceAll([]);
      return;
    }
    try {
      List<File> files = fileSystemController.findFile(folder!);
      fileController.replaceAll(files);
    } catch (e) {
      logger.e('list file failure:$e');
      fileController.replaceAll([]);
    }
  }

  Widget _buildFileTableWidget(BuildContext context) {
    final List<PlatformDataColumn> platformDataColumns = [];
    platformDataColumns.add(PlatformDataColumn(
      label: 'Name',
      name: 'name',
      dataType: DataType.string,
      align: TextAlign.left,
    ));
    platformDataColumns.add(PlatformDataColumn(
      label: 'MimeType',
      name: 'mimeType',
      dataType: DataType.string,
      align: TextAlign.left,
    ));
    platformDataColumns.add(PlatformDataColumn(
      label: 'Modified',
      name: 'modified',
      dataType: DataType.string,
      align: TextAlign.left,
    ));
    platformDataColumns.add(PlatformDataColumn(
      label: 'Size',
      name: 'size',
      dataType: DataType.int,
      align: TextAlign.right,
    ));

    return BindingDataTable2<File>(
      key: UniqueKey(),
      showCheckboxColumn: true,
      horizontalMargin: 15.0,
      columnSpacing: 0.0,
      platformDataColumns: platformDataColumns,
      controller: fileController,
      fixedLeftColumns: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title, withLeading: true, child: _buildFileTableWidget(context));
  }
}

extension on File {
  Widget get icon {
    if (mimeType == null) {
      return Icon(
        Icons.insert_drive_file,
        color: myself.primary,
      );
    }
    return Mimecon(
      mimetype: mimeType ?? this.mimeType,
      color: myself.primary,
      size: 36,
      isOutlined: true,
    );

    // return Icon(
    //   Icons.insert_drive_file,
    //   color: myself.primary,
    // );
  }
}
