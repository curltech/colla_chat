import 'package:colla_chat/pages/game/model/base/subject.dart';

/// 模型项目
class Project {
  String name;

  double nodeWidth = 200;

  double nodePadding = 10;

  double pixelRatio = 1;

  List<Subject> subjects = [];

  Project(this.name);

  void clear() {
    subjects.clear();
  }

  Project.fromJson(Map json)
      : name = json['name'] == '' ? null : json['name'],
        subjects = json['subjects'];

  Map<String, dynamic> toJson() {
    return {'name': name, 'subjects': subjects};
  }
}
