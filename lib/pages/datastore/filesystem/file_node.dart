import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';

class File extends Explorable {
  final String mimeType;

  File({super.name, required this.mimeType});
}

typedef FileNode = TreeNode<File>;
