import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';

/// 模型项目
class Project {
  String name;

  /// 基于主题域的节点列表
  Map<String, List<ModelNode>>? subjectModelNodes;

  List<NodeRelationship>? nodeRelationships;

  Project(this.name);

  Project.fromJson(Map json)
      : name = json['name'] == '' ? null : json['name'],
        subjectModelNodes = json['subjectModelNodes'],
        nodeRelationships = json['nodeRelationships'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subjectModelNodes': subjectModelNodes,
      'nodeRelationships': nodeRelationships
    };
  }
}
