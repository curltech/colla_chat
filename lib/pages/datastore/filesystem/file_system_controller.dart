import 'dart:core';
import 'dart:io';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:get/get.dart';

class FileSystemController {
  final RxMap<String, FolderNode> rootFolders = <String, FolderNode>{}.obs;
  TreeViewController? treeViewController;
  final TreeNode<Explorable> root = TreeNode.root();
  final Rx<Folder?> current = Rx<Folder?>(null);

  Rx<ExplorableNode?> currentNode = Rx<ExplorableNode?>(null);

  FileSystemController() {
    init();
  }

  clear() {
    rootFolders.clear();
    root.clear();
  }

  init() async {
    clear();
    Directory? applicationDirectory = await PathUtil.getApplicationDirectory();
    if (applicationDirectory != null) {
      addDirectory(applicationDirectory);
    }
    Directory applicationDocumentsDirectory =
        await PathUtil.getApplicationDocumentsDirectory();
    addDirectory(applicationDocumentsDirectory);
    Directory applicationSupportDirectory =
        await PathUtil.getApplicationSupportDirectory();
    addDirectory(applicationSupportDirectory);

    Directory? downloadsDirectory = await PathUtil.getDownloadsDirectory();
    if (downloadsDirectory != null) {
      addDirectory(downloadsDirectory);
    }
    Directory libraryDirectory = await PathUtil.getLibraryDirectory();
    addDirectory(libraryDirectory);
    Directory temporaryDirectory = await PathUtil.getTemporaryDirectory();
    addDirectory(temporaryDirectory);
    Directory? externalStorageDirectory =
        await PathUtil.getExternalStorageDirectory();
    if (externalStorageDirectory != null) {
      addDirectory(externalStorageDirectory);
    }

    List<ListenableNode> children = root.childrenAsList;
    for (var node in children) {
      treeViewController?.collapseNode(node as ITreeNode);
    }
  }

  FolderNode addDirectory(Directory directory) {
    Folder folder = Folder(name: directory.path, directory: directory);
    FolderNode folderNode = FolderNode(data: folder);
    root.add(folderNode);
    rootFolders[folder.name!] = folderNode;

    return folderNode;
  }

  deleteDirectory({FolderNode? node}) {
    Folder? folder;
    if (node != null) {
      node.delete();
    } else {
      folder = current.value;
      current.value = null;
    }
    rootFolders.remove(folder!.name);
  }

  findDirectory(FolderNode folderNode) {
    Directory? directory = folderNode.data?.directory;
    if (directory == null) {
      return;
    }
    List<FileSystemEntity> fileSystemEntities = directory.listSync();

    for (FileSystemEntity fileSystemEntity in fileSystemEntities) {
      FileStat fileStat = fileSystemEntity.statSync();
      FileSystemEntityType fileSystemEntityType = fileStat.type;
      if (fileSystemEntityType == FileSystemEntityType.directory) {
        FolderNode node = FolderNode(
            data: Folder(
                name: fileSystemEntity.path,
                directory: fileSystemEntity as Directory));
        folderNode.add(node);
      }
    }
  }
}

final FileSystemController fileSystemController = FileSystemController();
