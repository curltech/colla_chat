import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'dart:ui' as ui;

/// 模型主题
class Subject {
  String name;

  /// 节点的位置和大小
  double? x;
  double? y;
  double? width;
  double? height;

  ui.Image? image;

  /// 基于主题域的节点列表
  List<ModelNode> modelNodes = [];

  List<NodeRelationship> relationships = [];

  Subject(this.name);

  void clear() {
    modelNodes.clear();
    relationships.clear();
  }

  Subject.fromJson(Map json)
      : name = json['name'] == '' ? null : json['name'],
        x = json['x'],
        y = json['y'],
        width = json['width'],
        height = json['height'],
        modelNodes = json['modelNodes'],
        relationships = json['relationships'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'modelNodes': modelNodes,
      'relationships': relationships
    };
  }
}
