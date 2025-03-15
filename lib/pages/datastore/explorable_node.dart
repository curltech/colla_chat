import 'package:animated_tree_view/animated_tree_view.dart' as animated;
import 'package:checkable_treeview/checkable_treeview.dart' as checkable;

abstract class Explorable {
  String? name;
  String? comment;

  Explorable({this.name, this.comment});

  @override
  String toString() => name ?? '';

  Explorable.fromJson(Map json)
      : name = json['name'],
        comment = json['comment'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'comment': comment,
    };
  }
}

typedef AnimatedExplorableNode = animated.TreeNode<Explorable>;

typedef CheckableExplorableNode = checkable.TreeNode<Explorable>;
