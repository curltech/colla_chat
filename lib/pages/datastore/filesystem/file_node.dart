import 'dart:io';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';

class Folder extends Explorable {
  Directory directory;

  Folder({super.name, required this.directory});
}

typedef FolderNode = TreeNode<Folder>;

class File extends Explorable {
  final String mimeType;

  File({super.name, required this.mimeType});
}

typedef FileNode = TreeNode<File>;
