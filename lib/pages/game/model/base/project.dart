import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/tool/json_util.dart';

/// 模型项目
class Project {
  static const double nodeWidth = 140;

  static const double nodePadding = 10;

  static const double pixelRatio = 1;

  String name;

  List<Subject> subjects = [];

  Project(this.name);

  void clear() {
    subjects.clear();
  }

  Project.fromJson(Map json) : name = json['name'] == '' ? null : json['name'] {
    subjects = [];
    List<dynamic>? ss = json['subjects'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        Subject subject = Subject.fromJson(s);
        subjects.add(subject);
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'subjects': JsonUtil.toJson(subjects)};
  }
}
