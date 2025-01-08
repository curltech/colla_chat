import 'package:animated_tree_view/animated_tree_view.dart';

abstract class Explorable {
  final String name;
  final String? comment;
  final DateTime createdAt;

  Explorable(this.name, {this.comment}) : createdAt = DateTime.now();

  @override
  String toString() => name;
}

typedef ExplorableNode = TreeNode<Explorable>;
