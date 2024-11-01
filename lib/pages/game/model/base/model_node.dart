import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';

enum Scope { private, protected, public }

class Attribute {
  String name;
  late String scope;
  late String dataType;

  Attribute(this.name, {String? dataType, String? scope}) {
    this.scope = scope ?? Scope.public.name;
    this.dataType = dataType ?? DataType.string.name;
  }

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
  String name;
  late String scope;
  late String returnType;

  Method(this.name, {String? returnType, String? scope}) {
    this.scope = scope ?? Scope.public.name;
    this.returnType = returnType ?? DataType.string.name;
  }

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
  late String packageName;
  late bool isAbstract;

  List<Attribute> attributes = [];
  List<Method> methods = [];

  ModelNode(
      {required String name, this.isAbstract = false, this.packageName = ''})
      : super(name);

  ModelNode.fromJson(Map json) : super.fromJson(json) {
    packageName = json['packageName'] ?? '';
    isAbstract =
        json['isAbstract'] == true || json['isAbstract'] == 1 ? true : false;
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
      'packageName': packageName,
      'isAbstract': isAbstract,
      'attributes': JsonUtil.toJson(attributes),
      'methods': JsonUtil.toJson(methods)
    });
    return json;
  }
}
