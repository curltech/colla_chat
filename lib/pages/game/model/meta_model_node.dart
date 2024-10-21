import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:flutter/material.dart';

/// 元模型节点
class MetaModelNode extends Node {
  final String packageName;
  final Map<String, Type> attributes = {};
  final List<String> methods = [];
  final List<String> rules = [];

  MetaModelNode(this.packageName,
      {required String name, bool isAbstract = false})
      : super(name, isAbstract);
}
