import 'dart:core';
import 'dart:io' as io;

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/widgets/data_bind/tree_view.dart';
import 'package:get/get.dart';

class FileSystemController extends DataListController<FolderNode> {
  late final TreeViewController treeViewController;
  Rx<FolderNode?> currentNode = Rx<FolderNode?>(null);

  FileSystemController() {
    init();
  }

  init() async {
    clear();
    if (platformParams.mobile) {
      initMobile();
    } else if (platformParams.macos || platformParams.linux) {
      initMac();
      initMobile();
    } else if (platformParams.windows) {
      initWindows();
      initMobile();
    }
    treeViewController = TreeViewController(data.value);
  }

  initMac() {
    io.Directory root = io.Directory('/');
    addDirectory('/', root);
  }

  initWindows() {
    io.Directory root = io.Directory('c:/');
    addDirectory('c:/', root);
  }

  initMobile() async {
    io.Directory? applicationDirectory =
        await PathUtil.getApplicationDirectory();
    if (applicationDirectory != null) {
      addDirectory(
          AppLocalizations.t('Application Directory'), applicationDirectory);
    }
    io.Directory applicationDocumentsDirectory =
        await PathUtil.getApplicationDocumentsDirectory();
    addDirectory(AppLocalizations.t('Application Documents Directory'),
        applicationDocumentsDirectory);
    io.Directory applicationSupportDirectory =
        await PathUtil.getApplicationSupportDirectory();
    addDirectory(AppLocalizations.t('Application Support Directory'),
        applicationSupportDirectory);

    io.Directory? downloadsDirectory = await PathUtil.getDownloadsDirectory();
    if (downloadsDirectory != null) {
      addDirectory(
          AppLocalizations.t('Downloads Directory'), downloadsDirectory);
    }
    io.Directory libraryDirectory = await PathUtil.getLibraryDirectory();
    addDirectory(AppLocalizations.t('Library Directory'), libraryDirectory);
    io.Directory temporaryDirectory = await PathUtil.getTemporaryDirectory();
    addDirectory(AppLocalizations.t('Temporary Directory'), temporaryDirectory);
    io.Directory? externalStorageDirectory =
        await PathUtil.getExternalStorageDirectory();
    if (externalStorageDirectory != null) {
      addDirectory(AppLocalizations.t('External Storage Directory'),
          externalStorageDirectory);
    }
  }

  FolderNode addDirectory(String name, io.Directory directory) {
    Folder folder = Folder(name, directory: directory);
    FolderNode folderNode = FolderNode(folder);
    add(folderNode);

    return folderNode;
  }

  deleteDirectory({FolderNode? node}) {
    node ??= current;
    remove(node!);
  }

  findDirectory(FolderNode folderNode) {
    io.Directory directory = (folderNode.value as Folder).directory;
    List<io.FileSystemEntity> fileSystemEntities = directory.listSync();

    if (fileSystemEntities.isNotEmpty) {
      for (io.FileSystemEntity fileSystemEntity in fileSystemEntities) {
        io.FileStat fileStat = fileSystemEntity.statSync();
        io.FileSystemEntityType fileSystemEntityType = fileStat.type;
        if (fileSystemEntityType == io.FileSystemEntityType.directory) {
          FolderNode node = FolderNode(Folder(
              PathUtil.basename(fileSystemEntity.path),
              directory: fileSystemEntity as io.Directory));
          folderNode.children.add(node);
        }
      }
    } else {
      folderNode.canBeExpanded.value = false;
    }
  }

  List<File> findFile(Folder folder, {String? keyword}) {
    io.Directory? directory = folder.directory;
    List<io.FileSystemEntity> fileSystemEntities = directory.listSync();
    List<File> files = [];
    for (io.FileSystemEntity fileSystemEntity in fileSystemEntities) {
      io.FileStat fileStat = fileSystemEntity.statSync();
      io.FileSystemEntityType fileSystemEntityType = fileStat.type;
      if (fileSystemEntityType == io.FileSystemEntityType.file) {
        String name = PathUtil.basename(fileSystemEntity.path);
        if (keyword != null && keyword.isNotEmpty) {
          if (!name.contains(keyword)) {
            continue;
          }
        }
        File file = File(name, file: fileSystemEntity as io.File);
        files.add(file);
      }
    }
    return files;
  }
}

final FileSystemController fileSystemController = FileSystemController();
