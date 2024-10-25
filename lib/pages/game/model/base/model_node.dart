import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/tool/json_util.dart';

class Attribute {
  String? name;
  String? scope;
  String? dataType;

  Attribute.fromJson(Map json)
      : name = json['name'],
        scope = json['scope'],
        dataType = json['dataType'];

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({'name': name, 'scope': scope, 'dataType': dataType});

    return json;
  }
}

class Method {
  String? name;
  String? scope;
  String? returnType;

  Method.fromJson(Map json)
      : name = json['name'],
        scope = json['scope'],
        returnType = json['returnType'];

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({'name': name, 'scope': scope, 'returnType': returnType});

    return json;
  }
}

/// 模型节点
class ModelNode extends Node {
  List<Attribute> attributes = [];
  List<Method> methods = [];

  ModelNode(
      {required String name, bool isAbstract = false, String? packageName})
      : super(name, isAbstract, packageName: packageName);

  ModelNode.fromJson(Map json) : super.fromJson(json) {
    attributes = [];
    List<dynamic>? ss = json['attributes'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        Attribute attribute = Attribute.fromJson(s);
        attributes.add(attribute);
      }
    }
    methods = [];
    ss = json['methods'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        Method method = Method.fromJson(s);
        methods.add(method);
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'attributes': JsonUtil.toJson(attributes),
      'methods': JsonUtil.toJson(methods)
    });
    return json;
  }
}
