import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:get/get.dart';

class ModelProjectController {
  /// 元模型
  late final Rx<Project> metaProject;

  /// 当前模型
  final Rx<Project?> project = Rx<Project?>(null);

  /// 当前模型的文件名
  final Rx<String?> filename = Rx<String?>(null);
  final Rx<String?> currentSubjectName = Rx<String?>(null);
  final Rx<ModelNode?> selectedModelNode = Rx<ModelNode?>(null);
  final Rx<NodeRelationship?> selectedRelationship =
      Rx<NodeRelationship?>(null);

  final Rx<ModelNode?> canAddModelNode = Rx<ModelNode?>(null);
  final Rx<RelationshipType?> canAddRelationship = Rx<RelationshipType?>(null);

  final ModelNode typeModelNode =
      ModelNode(name: 'type', nodeType: NodeType.type.name);
  final ModelNode imageModelNode =
      ModelNode(name: 'image', nodeType: NodeType.image.name);
  final ModelNode shapeModelNode =
      ModelNode(name: 'shape', nodeType: NodeType.shape.name);
  final ModelNode remarkModelNode =
      ModelNode(name: 'remark', nodeType: NodeType.remark.name);

  ModelProjectController() {
    initMetaProject();
  }

  initMetaProject() {
    Project metaProject = Project('meta');
    Subject subject = Subject('meta');
    subject.modelNodes = {
      typeModelNode.id: typeModelNode,
      imageModelNode.id: imageModelNode,
      shapeModelNode.id: shapeModelNode,
      remarkModelNode.id: remarkModelNode,
    };
    subject.relationships = {};
    NodeRelationship nodeRelationship = NodeRelationship(
        typeModelNode, imageModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(imageModelNode, typeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);

    nodeRelationship = NodeRelationship(imageModelNode, shapeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(shapeModelNode, imageModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);

    nodeRelationship = NodeRelationship(typeModelNode, shapeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(shapeModelNode, typeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);

    nodeRelationship = NodeRelationship(imageModelNode, remarkModelNode,
        relationshipType: RelationshipType.reference.name,
        allowRelationshipTypes: {RelationshipType.reference.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(shapeModelNode, remarkModelNode,
        relationshipType: RelationshipType.reference.name,
        allowRelationshipTypes: {RelationshipType.reference.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(typeModelNode, remarkModelNode,
        relationshipType: RelationshipType.reference.name,
        allowRelationshipTypes: {RelationshipType.reference.name});
    subject.add(nodeRelationship);

    metaProject.subjects = {subject.name: subject};

    this.metaProject = Rx<Project>(metaProject);
  }

  Subject? getCurrentSubject() {
    if (project.value != null && currentSubjectName.value != null) {
      return project.value!.subjects[currentSubjectName.value];
    }
    return null;
  }

  ModelNode? getModelNode(String id) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        return subject.modelNodes[id];
      }
    }

    return null;
  }

  removeModelNode(ModelNode modelNode) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        if (subject.modelNodes.containsKey(modelNode.id)) {
          subject.modelNodes.remove(modelNode.id);

          return;
        }
      }
    }
  }

  removeRelationship(NodeRelationship relationship) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        if (subject.containsKey(relationship)) {
          subject.remove(relationship);

          return;
        }
      }
    }
  }

  List<ModelNode>? getAllModelNodes() {
    List<ModelNode>? modelNodes;
    List<Subject> subjects = metaProject.value.subjects.values.toList();
    for (Subject subject in subjects) {
      if (subject.modelNodes.isNotEmpty) {
        modelNodes ??= [];
      }
      modelNodes!.addAll(subject.modelNodes.values);
    }

    return modelNodes;
  }

  Set<RelationshipType>? getAllAllowRelationshipTypes() {
    Set<RelationshipType>? relationshipTypes;
    List<Subject> subjects = metaProject.value.subjects.values.toList();
    for (Subject subject in subjects) {
      if (subject.relationships.isNotEmpty) {
        relationshipTypes ??= {};
      }
      for (NodeRelationship nodeRelationship in subject.relationships.values) {
        Set<String>? allowRelationshipTypes =
            nodeRelationship.allowRelationshipTypes;
        if (allowRelationshipTypes == null) {
          continue;
        }
        for (String allowRelationshipType in allowRelationshipTypes.toList()) {
          RelationshipType? type = StringUtil.enumFromString(
              RelationshipType.values, allowRelationshipType);
          if (type != null) {
            relationshipTypes!.add(type);
          }
        }
      }
    }

    return relationshipTypes;
  }
}

final ModelProjectController modelProjectController = ModelProjectController();
