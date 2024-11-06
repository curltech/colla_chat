import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'dart:ui' as ui;

enum Scope { private, protected, public }

class Attribute {
  String name;
  late String scope;
  late String dataType;

  AttributeTextComponent? attributeTextComponent;

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

  MethodTextComponent? methodTextComponent;

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

enum NodeType { shape, image, type, remark }

enum ShapeType {
  rect,
  rrect,
  circle,
  oval,
  diamond,
  drrect,
  arc,
  paragraph,
  vertices,
  imageRect,
  image
}

/// 模型节点
class ModelNode extends Node {
  late String nodeType;
  String? shapeType;

  String? content;

  ui.Image? image;

  List<Attribute> attributes = [];
  List<Method> methods = [];

  ModelNode({required String name, String? nodeType, this.shapeType})
      : super(name) {
    this.nodeType = nodeType ?? NodeType.type.name;
  }

  ModelNode.fromJson(Map json) : super.fromJson(json) {
    nodeType = json['nodeType'] ?? NodeType.type.name;
    shapeType = json['shapeType'];
    content = json['content'];

    List<dynamic>? ss = json['attributes'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        Attribute attribute = Attribute.fromJson(s);
        attributes.add(attribute);
      }
    }

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
      'nodeType': nodeType,
      'shapeType': shapeType,
      'content': content,
      'attributes': JsonUtil.toJson(attributes),
      'methods': JsonUtil.toJson(methods)
    });
    return json;
  }
}