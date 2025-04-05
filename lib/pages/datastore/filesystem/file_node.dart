import 'dart:io' as io;
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/data_bind/tree_view.dart';
import 'package:flutter/material.dart';

class Folder extends Explorable {
  io.Directory directory;

  Folder(super.name, {required this.directory});
}

class FolderNode extends ExplorableNode {
  FolderNode(Folder super.folder);

  @override
  Widget? get icon {
    return isExpanded.value
        ? Icon(Icons.folder_open, color: myself.primary)
        : Icon(Icons.folder, color: myself.primary);
  }
}

class File extends Explorable {
  late final String changed;
  late final String modified;
  late final String accessed;
  late final int size;
  late final String? mimeType;
  bool checked = false;
  io.File file;

  File(super.name, {required this.file}) {
    io.FileStat stat = file.statSync();
    changed = DateUtil.formatDate(stat.changed);
    modified = DateUtil.formatDate(stat.modified);
    accessed = DateUtil.formatDate(stat.accessed);
    size = stat.size;
    mimeType = FileUtil.mimeType(file.path);
  }

  File.fromJson(super.json)
      : changed = json['changed'],
        modified = json['modified'],
        accessed = json['accessed'],
        size = json['size'],
        file = io.File(json['file']),
        mimeType = json['mimeType'],
        checked = json['checked'] ?? false,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'changed': changed,
      'modified': modified,
      'accessed': accessed,
      'size': size,
      'file': file.path,
      'mimeType': mimeType,
      'checked': checked,
    });

    return json;
  }
}

class FileNode extends ExplorableNode {
  FileNode(File super.value);

  @override
  Widget? get icon {
    return Icon(Icons.insert_drive_file, color: myself.primary);
  }
}
