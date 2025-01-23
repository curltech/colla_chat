import 'dart:io' as io;

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/file_util.dart';

class Folder extends Explorable {
  io.Directory directory;

  Folder({super.name, required this.directory});
}

typedef FolderNode = TreeNode<Folder>;

class File extends Explorable {
  late final String changed;
  late final String modified;
  late final String accessed;
  late final int size;
  late final String? mimeType;
  bool checked = false;
  io.File file;

  File({super.name, required this.file}) {
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

typedef FileNode = TreeNode<File>;
