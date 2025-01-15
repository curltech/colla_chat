import 'package:animated_tree_view/animated_tree_view.dart';

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

typedef ExplorableNode = TreeNode<Explorable>;

class Folder extends Explorable {
  Folder({super.name});
}

typedef FolderNode = TreeNode<Folder>;
