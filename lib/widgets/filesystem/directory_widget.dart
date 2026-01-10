import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/widgets/data_bind/tree_view.dart';
import 'package:colla_chat/widgets/filesystem/directory_controller.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'file_node.dart';

/// 文件管理功能主页面，带有路由回调函数
class DirectoryWidget extends StatelessWidget {
  late final DirectoryController directoryController;
  final Function(FolderNode folderNode)? onSelected;
  final Function(FolderNode folderNode)? onToggleNodeExpansion;
  final bool readOnly;

  DirectoryWidget(
      {super.key,
      DirectoryController? directoryController,
      this.readOnly = true,
      this.onSelected,
      this.onToggleNodeExpansion}) {
    if (directoryController == null) {
      this.directoryController = DirectoryController();
    } else {
      this.directoryController = directoryController;
    }
  }

  /// 单击表示编辑属性
  void _onTap(BuildContext context, FolderNode folderNode) {
    directoryController.currentNode.value = folderNode;
    onSelected?.call(folderNode);
  }

  Widget _buildFolderButtonWidget(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New folder'),
            onPressed: () {
              _addFolder(context);
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete folder'),
            onPressed: () async {
              _deleteFolder(context);
            },
            icon: Icon(
              Icons.remove,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Rename folder name'),
            onPressed: () async {
              _renameFolder(context);
            },
            icon: Icon(
              Icons.drive_file_rename_outline_outlined,
              color: myself.primary,
            )),
      ],
    );
  }

  Future<void> _addFolder(BuildContext context) async {
    FolderNode? folderNode = directoryController.currentNode.value;
    if (folderNode == null) {
      return;
    }
    Folder? folder = folderNode.value as Folder?;
    if (folder == null) {
      return;
    }
    String path = folder.directory.path;
    String? content = await DialogUtil.showTextFormField(
        context: context, title: 'New folder name');
    if (content != null) {
      String name = p.join(path, content);
      Directory directory = Directory(name);
      directory.createSync();
      folderNode.children.add(FolderNode(
          Folder(PathUtil.basename(directory.path), directory: directory)));
    }
  }

  Future<void> _deleteFolder(BuildContext context) async {
    FolderNode? folderNode = directoryController.currentNode.value;
    if (folderNode == null) {
      return;
    }
    Folder? folder = folderNode.value as Folder?;
    if (folder == null) {
      return;
    }
    bool? confirm = await DialogUtil.confirm(
        context: context,
        content: 'Do you confirm delete folder:${folder.name}?');
    if (confirm != null && confirm) {
      Directory directory = folder.directory;
      folderNode.parent?.children.remove(folderNode);
      directory.deleteSync(recursive: true);
    }
  }

  Future<void> _renameFolder(BuildContext context) async {
    Folder? folder = directoryController.currentNode.value?.value as Folder?;
    if (folder == null) {
      return;
    }
    String path = folder.directory.path;
    String name = PathUtil.basename(path);
    String? content = await DialogUtil.showTextFormField(
        context: context, title: 'New folder name', content: name);
    if (content != null && content != name) {
      name = p.join(p.dirname(path), content);
      Directory directory = folder.directory.renameSync(name);
      folder.directory = directory;
    }
  }

  Widget _buildTreeViewWidget(BuildContext context) {
    return TreeView(
      treeViewController: directoryController.treeViewController,
      onTap: (ExplorableNode node) {
        _onTap(context, node as FolderNode);
      },
      toggleNodeExpansion: (ExplorableNode node) {
        _onToggleNodeExpansion(node as FolderNode);
      },
    );
  }

  void _onToggleNodeExpansion(FolderNode node) {
    if (node.children.isEmpty) {
      try {
        directoryController.findDirectory(node);
      } catch (e) {
        DialogUtil.error(content: 'list directory failure:$e');
      }
    }
    onToggleNodeExpansion?.call(node);
  }

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return _buildTreeViewWidget(context);
    }
    return Column(
      children: [
        _buildFolderButtonWidget(context),
        Expanded(child: _buildTreeViewWidget(context))
      ],
    );
  }
}
