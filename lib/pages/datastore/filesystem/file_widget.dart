import 'dart:io' as io;

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_system_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mimecon/mimecon.dart';
import 'package:path/path.dart' as p;

/// 文件管理功能主页面，带有路由回调函数
class FileWidget extends StatelessWidget with TileDataMixin {
  FileWidget({super.key}) {
    fileSystemController.currentNode.addListener(() {
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

  final RxBool gridMode = false.obs;

  /// 长按表示进一步的操作
  Future<void> _onLongPress(BuildContext context, File file) async {
    fileController.current = file;
    List<ActionData> popActionData = [];
    popActionData.add(ActionData(
        label: 'New',
        tooltip: 'New',
        icon: Icon(
          Icons.add,
          color: myself.primary,
        )));
    popActionData.add(ActionData(
        label: 'Delete',
        tooltip: 'Delete',
        icon: Icon(
          Icons.remove,
          color: myself.primary,
        )));
    popActionData.add(ActionData(
        label: 'Rename',
        tooltip: 'Rename',
        icon: Icon(
          Icons.drive_file_rename_outline_outlined,
          color: myself.primary,
        )));

    await MenuUtil.showPopMenu(
      context,
      onPressed: (BuildContext context, int index, String label,
          {String? value}) {
        _onPopAction(context, file, index, label, value: value);
      },
      height: 200,
      width: appDataProvider.secondaryBodyWidth,
      actions: popActionData,
    );
  }

  _onPopAction(BuildContext context, File file, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'New':
        _addFile(context);
        break;
      case 'Delete':
        _deleteFile(context);
        break;
      case 'Rename':
        _renameFile(context);
        break;
      default:
    }
  }

  Future<void> _addFile(BuildContext context) async {
    FolderNode? folderNode = fileSystemController.currentNode.value;
    if (folderNode == null) {
      return;
    }
    Folder? folder = folderNode.data;
    if (folder == null) {
      return;
    }
    String path = folder.directory.path;
    String? content = await DialogUtil.showTextFormField(
        context: context, title: 'New file name');
    if (content != null) {
      String name = p.join(path, content);
      io.File file = io.File(name);
      file.createSync();
      File f = File(name: content, file: file);
      fileController.add(f);
    }
  }

  Future<void> _deleteFile(BuildContext context) async {
    bool? confirm;
    List<File> files = fileController.checked;
    if (files.isEmpty) {
      File? file = fileController.current;
      if (file == null) {
        return;
      }
      confirm = await DialogUtil.confirm(
          context: context,
          content: 'Do you confirm delete current file:${file.name}?');
      if (confirm != null && confirm) {
        files.add(file);
      }
    } else {
      confirm = await DialogUtil.confirm(
          context: context,
          content: 'Do you confirm delete selected ${files.length} files?');
    }
    if (confirm != null && confirm) {
      for (File file in files) {
        file.file.delete();
        fileController.data.remove(file);
      }
    }
  }

  Future<void> _renameFile(BuildContext context) async {
    File? file = fileController.current;
    if (file == null) {
      return;
    }
    String path = file.file.path;
    String name = PathUtil.basename(path);
    String? content = await DialogUtil.showTextFormField(
        context: context, title: 'New file name', content: name);
    if (content != null && content != name) {
      name = p.join(p.dirname(path), content);
      io.File f = file.file.renameSync(name);
      file.file = f;
      file.name = content;
    }
  }

  _buildFiles() {
    Folder? folder = fileSystemController.currentNode.value?.data;
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

  Widget _buildFilePathWidget(BuildContext context) {
    return Obx(() {
      File? file = fileController.current;
      String? path = file?.file.path;

      return CommonAutoSizeTextFormField(
        labelText: AppLocalizations.t('Path'),
        readOnly: true,
        controller: TextEditingController(text: path ?? ''),
      );
    });
  }

  Widget _buildFileWrapWidget(BuildContext context) {
    return Obx(() {
      List<Widget> children = [];
      for (File file in fileController.data) {
        children.add(InkWell(
            onLongPress: () {
              _onLongPress(context, file);
            },
            onTap: () {
              fileController.current = file;
            },
            child: SizedBox(
                width: 100,
                height: 120,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      file.icon,
                      Expanded(child: CommonAutoSizeText(file.name!))
                    ]))));
      }
      return SingleChildScrollView(
          // padding: EdgeInsets.zero,
          child: Wrap(
        spacing: 10.0,
        // alignment: WrapAlignment.center,
        // runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ));
    });
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
      onLongPress: (int index) {
        File file = fileController.data[index];
        _onLongPress(context, file);
      },
      onTap: (int index) {
        File file = fileController.data[index];
        fileController.current = file;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<Widget> rightWidgets = [
        IconButton(
          color: myself.primary,
          icon: Obx(() {
            return Icon(
              gridMode.isTrue ? Icons.list : Icons.grid_on,
              color: Colors.white,
            );
          }),
          onPressed: () {
            gridMode(!gridMode.value);
          },
          tooltip: AppLocalizations.t('Toggle grid mode'),
        )
      ];
      return AppBarView(
          title: title,
          withLeading: true,
          rightWidgets: rightWidgets,
          child: Column(
            children: [
              _buildFilePathWidget(context),
              Expanded(
                child: gridMode.isTrue
                    ? _buildFileWrapWidget(context)
                    : _buildFileTableWidget(context),
              )
            ],
          ));
    });
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
      mimetype: mimeType,
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
