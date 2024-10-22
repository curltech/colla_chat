import 'package:colla_chat/pages/game/model/base/node.dart';

/// 模型节点
class ModelNode extends Node {
  String packageName;
  Map<String, Type> attributes = {};
  List<String> methods = [];
  List<String> rules = [];

  ModelNode(this.packageName, {required String name, bool isAbstract = false})
      : super(name, isAbstract);

  ModelNode.fromJson(super.json)
      : packageName = json['packageName'],
        attributes = json['attributes'],
        methods = json['methods'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'packageName': packageName,
      'attributes': attributes,
      'methods': methods
    });
    return json;
  }
}
