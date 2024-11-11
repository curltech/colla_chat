import 'dart:convert';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;

/// 元模型建模器
class MetaModellerWidget extends StatelessWidget with TileDataMixin {
  final ModelNodeEditWidget modelNodeEditWidget = ModelNodeEditWidget();

  ModelFlameGame? modelFlameGame;

  MetaModellerWidget({super.key}) {
    indexWidgetProvider.define(modelNodeEditWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'modeller';

  @override
  IconData get iconData => Icons.model_training_outlined;

  @override
  String get title => 'Modeller';

  _addSubject() async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    String? subjectName = await DialogUtil.showTextFormField(
        title: 'New subject',
        content: 'Please input new subject name',
        tip: 'unknown');
    if (subjectName != null) {
      Rect rect = project.rect;
      Subject subject = Subject(subjectName);
      subject.x = rect.right + Project.nodePadding;
      subject.y = rect.top;
      modelProjectController.currentSubjectName.value = subject.name;
      project.subjects[subject.name] = subject;
      modelFlameGame?.moveTo();
    }
  }

  _selectSubject() async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    List<Option<String>> options = [];
    for (var subject in modelProjectController.project.value!.subjects.values) {
      options.add(Option(subject.name, subject.name));
    }
    String? subjectName = await DialogUtil.showSelectDialog<String>(
        title: const CommonAutoSizeText('Select subject'), items: options);
    if (subjectName != null) {
      modelProjectController.currentSubjectName.value = subjectName;
      modelFlameGame?.moveTo();
    }
  }

  List<Widget> _buildSubjectButtons() {
    Project? project = modelProjectController.project.value;
    return [
      IconButton(
        onPressed: project != null
            ? () async {
                await _addSubject();
              }
            : null,
        icon: Icon(
          Icons.electric_meter,
          color: myself.primary,
        ),
        tooltip: AppLocalizations.t('New subject'),
      ),
      IconButton(
        onPressed: project != null
            ? () async {
                _selectSubject();
              }
            : null,
        icon: Icon(
          Icons.list_alt_outlined,
          color: myself.primary,
        ),
        tooltip: AppLocalizations.t('Select subject'),
      )
    ];
  }

  List<Widget> _buildMetaNodeButtons() {
    List<ModelNode>? allowModelNodes =
        modelProjectController.getAllModelNodes();
    Project? project = modelProjectController.project.value;
    List<Widget> btns = [];
    for (var allowModelNode in allowModelNodes!) {
      String nodeType = allowModelNode.nodeType;
      Widget? btnIcon;
      if (nodeType == NodeType.image.name) {
        if (allowModelNode.content != null) {
          btnIcon =
              ImageUtil.buildImageWidget(imageContent: allowModelNode.content);
        }
        btnIcon ??= Icon(
          Icons.image_outlined,
          color: modelProjectController.canAddModelNode.value == allowModelNode
              ? Colors.amber
              : myself.primary,
        );
      }
      if (nodeType == NodeType.type.name) {
        btnIcon ??= Icon(
          Icons.newspaper_outlined,
          color: modelProjectController.canAddModelNode.value == allowModelNode
              ? Colors.amber
              : myself.primary,
        );
      }
      if (nodeType == NodeType.remark.name) {
        btnIcon ??= Icon(
          Icons.comment,
          color: modelProjectController.canAddModelNode.value == allowModelNode
              ? Colors.amber
              : myself.primary,
        );
      }
      if (nodeType == NodeType.shape.name) {
        btnIcon ??= Icon(
          Icons.rectangle_outlined,
          color: modelProjectController.canAddModelNode.value == allowModelNode
              ? Colors.amber
              : myself.primary,
        );
      }

      Widget btn = IconButton(
        onPressed: project != null
            ? () {
                _modelNodeAction(allowModelNode);
              }
            : null,
        icon: btnIcon!,
        tooltip: AppLocalizations.t('New ${allowModelNode.name}'),
      );
      btns.add(btn);
    }
    return btns;
  }

  _modelNodeAction(ModelNode modelNode) {
    ModelNode? canAddModelNode = modelProjectController.canAddModelNode.value;
    if (canAddModelNode == null) {
      modelProjectController.canAddModelNode.value = modelNode;
    } else {
      if (modelNode != canAddModelNode) {
        modelProjectController.canAddModelNode.value = modelNode;
      } else {
        modelProjectController.canAddModelNode.value = null;
      }
    }
    modelProjectController.canAddRelationship.value = null;
  }

  List<Widget> _buildRelationshipButtons() {
    Set<RelationshipType>? allowRelationshipTypes =
        modelProjectController.getAllAllowRelationshipTypes();
    Project? project = modelProjectController.project.value;
    List<Widget> btns = [
      IconButton(
        onPressed: project != null
            ? () {
                RelationshipType? addRelationshipStatus =
                    modelProjectController.canAddRelationship.value;
                if (addRelationshipStatus != RelationshipType.reference) {
                  modelProjectController.canAddRelationship.value =
                      RelationshipType.reference;
                } else {
                  modelProjectController.canAddRelationship.value = null;
                }
                modelProjectController.canAddModelNode.value = null;
              }
            : null,
        icon: Icon(
          Icons.linear_scale_outlined,
          color: modelProjectController.canAddRelationship.value ==
                  RelationshipType.reference
              ? Colors.amber
              : myself.primary,
        ),
        tooltip: AppLocalizations.t('New reference relationship'),
      )
    ];
    if (allowRelationshipTypes == null ||
        allowRelationshipTypes.contains(RelationshipType.association)) {
      btns.add(
        IconButton(
          onPressed: project != null
              ? () {
                  RelationshipType? addRelationshipStatus =
                      modelProjectController.canAddRelationship.value;
                  if (addRelationshipStatus != RelationshipType.association) {
                    modelProjectController.canAddRelationship.value =
                        RelationshipType.association;
                  } else {
                    modelProjectController.canAddRelationship.value = null;
                  }
                  modelProjectController.canAddModelNode.value = null;
                }
              : null,
          icon: Icon(
            Icons.stacked_line_chart_outlined,
            color: modelProjectController.canAddRelationship.value ==
                    RelationshipType.association
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New association relationship'),
        ),
      );
    }
    if (allowRelationshipTypes == null ||
        allowRelationshipTypes.contains(RelationshipType.generalization)) {
      btns.add(
        IconButton(
          onPressed: project != null
              ? () {
                  RelationshipType? addRelationshipStatus =
                      modelProjectController.canAddRelationship.value;
                  if (addRelationshipStatus !=
                      RelationshipType.generalization) {
                    modelProjectController.canAddRelationship.value =
                        RelationshipType.generalization;
                  } else {
                    modelProjectController.canAddRelationship.value = null;
                  }
                  modelProjectController.canAddModelNode.value = null;
                }
              : null,
          icon: Icon(
            Icons.line_style_outlined,
            color: modelProjectController.canAddRelationship.value ==
                    RelationshipType.generalization
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New generalization relationship'),
        ),
      );
    }
    if (allowRelationshipTypes == null ||
        allowRelationshipTypes.contains(RelationshipType.realization)) {
      btns.add(
        IconButton(
          onPressed: project != null
              ? () {
                  RelationshipType? addRelationshipStatus =
                      modelProjectController.canAddRelationship.value;
                  if (addRelationshipStatus != RelationshipType.realization) {
                    modelProjectController.canAddRelationship.value =
                        RelationshipType.realization;
                  } else {
                    modelProjectController.canAddRelationship.value = null;
                  }
                  modelProjectController.canAddModelNode.value = null;
                }
              : null,
          icon: Icon(
            Icons.line_axis_outlined,
            color: modelProjectController.canAddRelationship.value ==
                    RelationshipType.realization
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New realization relationship'),
        ),
      );
    }
    if (allowRelationshipTypes == null ||
        allowRelationshipTypes.contains(RelationshipType.dependency)) {
      btns.add(
        IconButton(
          onPressed: project != null
              ? () {
                  RelationshipType? addRelationshipStatus =
                      modelProjectController.canAddRelationship.value;
                  if (addRelationshipStatus != RelationshipType.dependency) {
                    modelProjectController.canAddRelationship.value =
                        RelationshipType.dependency;
                  } else {
                    modelProjectController.canAddRelationship.value = null;
                  }
                  modelProjectController.canAddModelNode.value = null;
                }
              : null,
          icon: Icon(
            Icons.line_weight_outlined,
            color: modelProjectController.canAddRelationship.value ==
                    RelationshipType.dependency
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New dependency relationship'),
        ),
      );
    }
    if (allowRelationshipTypes == null ||
        allowRelationshipTypes.contains(RelationshipType.aggregation)) {
      btns.add(
        IconButton(
          onPressed: project != null
              ? () {
                  RelationshipType? addRelationshipStatus =
                      modelProjectController.canAddRelationship.value;
                  if (addRelationshipStatus != RelationshipType.aggregation) {
                    modelProjectController.canAddRelationship.value =
                        RelationshipType.aggregation;
                  } else {
                    modelProjectController.canAddRelationship.value = null;
                  }
                  modelProjectController.canAddModelNode.value = null;
                }
              : null,
          icon: Icon(
            Icons.blur_linear_outlined,
            color: modelProjectController.canAddRelationship.value ==
                    RelationshipType.aggregation
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New aggregation relationship'),
        ),
      );
    }
    if (allowRelationshipTypes == null ||
        allowRelationshipTypes.contains(RelationshipType.composition)) {
      btns.add(
        IconButton(
          onPressed: project != null
              ? () {
                  RelationshipType? addRelationshipStatus =
                      modelProjectController.canAddRelationship.value;
                  if (addRelationshipStatus != RelationshipType.composition) {
                    modelProjectController.canAddRelationship.value =
                        RelationshipType.composition;
                  } else {
                    modelProjectController.canAddRelationship.value = null;
                  }
                  modelProjectController.canAddModelNode.value = null;
                }
              : null,
          icon: Icon(
            Icons.format_line_spacing_outlined,
            color: modelProjectController.canAddRelationship.value ==
                    RelationshipType.composition
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New aggregation relationship'),
        ),
      );
    }

    return btns;
  }

  delete() async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    ModelNode? modelNode = modelProjectController.selectedModelNode.value;
    if (modelNode != null) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm to delete model node:${modelNode.name}?');
      if (confirm != null && confirm) {
        NodeFrameComponent? nodeFrameComponent = modelNode.nodeFrameComponent;
        if (nodeFrameComponent != null) {
          nodeFrameComponent.subject.modelNodes.remove(modelNode.id);
          nodeFrameComponent.removeFromParent();
        }
      }
    }
    NodeRelationship? nodeRelationship =
        modelProjectController.selectedRelationship.value;
    if (nodeRelationship != null) {
      bool? confirm = await DialogUtil.confirm(
          content:
              'Do you confirm to delete node relationship:${nodeRelationship.srcId}-${nodeRelationship.dstId}?');
      if (confirm != null && confirm) {
        NodeRelationshipComponent? nodeRelationshipComponent =
            nodeRelationship.nodeRelationshipComponent;
        if (nodeRelationshipComponent != null) {
          modelProjectController.removeRelationship(nodeRelationship);
          nodeRelationshipComponent.removeFromParent();
        }
      }
    }
  }

  Widget _buildToolPanelWidget(BuildContext context) {
    return Obx(() {
      Project? project = modelProjectController.project.value;
      var children = [
        ..._buildSubjectButtons(),
        ..._buildMetaNodeButtons(),
        ..._buildRelationshipButtons(),
        IconButton(
          onPressed: project != null ? delete : null,
          icon: Icon(
            Icons.delete_outline,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('Delete'),
        ),
      ];
      return appDataProvider.secondaryBodyLandscape
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: children,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: children,
            );
    });
  }

  _newProject() async {
    String? projectName = await DialogUtil.showTextFormField(
        title: 'New project',
        content: 'Please input new project name',
        tip: 'unknown');
    if (projectName != null) {
      modelProjectController.project.value = Project(projectName);
    }
  }

  _openProject() async {
    XFile? xfile = await FileUtil.selectFile(allowedExtensions: ['json']);
    if (xfile == null) {
      return;
    }
    String content = await xfile.readAsString();
    Map<String, dynamic> json = JsonUtil.toJson(content);
    Project project = Project.fromJson(json);
    modelProjectController.project.value = project;
    if (project.subjects.isEmpty) {
      return;
    }
    modelProjectController.currentSubjectName.value =
        project.subjects.values.first.name;
    for (Subject subject in project.subjects.values) {
      for (NodeRelationship relationship
          in subject.relationships.values.toList()) {
        ModelNode? modelNode =
            modelProjectController.getModelNode(relationship.srcId);
        if (modelNode == null) {
          subject.remove(relationship);
        } else {
          modelNode = modelProjectController.getModelNode(relationship.dstId);
          if (modelNode == null) {
            subject.remove(relationship);
          }
        }
      }
    }
  }

  _saveProject() async {
    String content =
        JsonUtil.toJsonString(modelProjectController.project.value);
    String? filename = await FileUtil.saveAsFile(
        modelProjectController.project.value!.name,
        utf8.encode(content),
        'json');
    modelProjectController.filename.value = filename;
  }

  List<Widget> _buildProjectButtons() {
    Project? project = modelProjectController.project.value;
    return [
      IconButton(
        onPressed: () {
          _newProject();
        },
        icon: const Icon(Icons.newspaper_sharp),
        tooltip: AppLocalizations.t('New project'),
      ),
      IconButton(
        onPressed: () {
          _openProject();
        },
        icon: const Icon(Icons.file_open),
        tooltip: AppLocalizations.t('Open project'),
      ),
      IconButton(
        onPressed: project != null
            ? () async {
                await _saveProject();
              }
            : null,
        icon: const Icon(Icons.save),
        tooltip: AppLocalizations.t('Save project'),
      ),
    ];
  }

  loadImage(ModelNode modelNode) async {
    if (modelNode.image == null && modelFlameGame != null) {
      ui.Image? image;
      if (modelNode.content != null) {
        image = await modelFlameGame!.images
            .fromBase64('${modelNode.name}.png', modelNode.content!);
      }
      image ??= await modelFlameGame!.images.load('colla.png');
      modelNode.image = image;
    }
  }

  _openMetaProject() async {
    XFile? xfile = await FileUtil.selectFile(allowedExtensions: ['json']);
    if (xfile == null) {
      return;
    }
    String content = await xfile.readAsString();
    Map<String, dynamic> json = JsonUtil.toJson(content);
    Project metaProject = Project.fromJson(json);
    modelProjectController.metaProject.value = metaProject;
    List<ModelNode>? modelNodes = modelProjectController.getAllModelNodes();
    if (modelNodes != null && modelNodes.isNotEmpty) {
      for (var modelNode in modelNodes) {
        loadImage(modelNode);
      }
    }

    modelProjectController.project.value = null;
  }

  List<Widget> _buildMetaProjectButtons() {
    return [
      IconButton(
        onPressed: () {
          _openMetaProject();
        },
        icon: const Icon(Icons.open_in_browser_outlined),
        tooltip: AppLocalizations.t('Open meta project'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Project? metaProject = modelProjectController.metaProject.value;
      Project? project = modelProjectController.project.value;
      List<Widget> rightWidgets = [
        ..._buildMetaProjectButtons(),
        ..._buildProjectButtons(),
      ];
      modelFlameGame = ModelFlameGame();
      var children = [
        _buildToolPanelWidget(context),
        Expanded(
            child: GameWidget(
          key: UniqueKey(),
          game: modelFlameGame!,
        ))
      ];
      String title = AppLocalizations.t(this.title);
      title = '$title-${metaProject.name}';
      if (project != null) {
        title = '$title-${project.name}';
      }
      return ListenableBuilder(
          listenable: appDataProvider,
          builder: (BuildContext context, Widget? _) {
            return AppBarView(
                title: title,
                withLeading: true,
                rightWidgets: rightWidgets,
                child: appDataProvider.secondaryBodyLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      )
                    : Column(
                        children: children,
                      ));
          });
    });
  }
}
