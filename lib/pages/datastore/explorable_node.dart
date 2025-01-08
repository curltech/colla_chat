import 'package:animated_tree_view/animated_tree_view.dart';

abstract class Explorable {
  final String name;
  final String? comment;

  Explorable(this.name, {this.comment});

  @override
  String toString() => name;
}

typedef ExplorableNode = TreeNode<Explorable>;

class Folder extends Explorable {
  Folder(super.name);
}

typedef FolderNode = TreeNode<Folder>;
