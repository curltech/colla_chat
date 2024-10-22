import 'package:colla_chat/pages/game/model/base/node.dart';

/// 模型节点
class ModelNode extends Node {
  Map<String, Type> attributes = {};
  List<String> methods = [];
  List<String> rules = [];

  ModelNode(
      {required String name, bool isAbstract = false, String? packageName})
      : super(name, isAbstract, packageName: packageName);

  ModelNode.fromJson(super.json)
      : attributes = json['attributes'],
        methods = json['methods'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({'attributes': attributes, 'methods': methods});
    return json;
  }
}
