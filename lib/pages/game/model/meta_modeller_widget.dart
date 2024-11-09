import 'dart:convert';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 元模型建模器
class MetaModellerWidget extends StatelessWidget with TileDataMixin {
  final ModelFlameGame modelFlameGame = ModelFlameGame();
  final ModelNodeEditWidget modelNodeEditWidget = ModelNodeEditWidget();

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
      subject.x = rect.left;
      subject.y = rect.top;
      modelProjectController.currentSubjectName.value = subject.name;
      project.subjects[subject.name] = subject;
      modelFlameGame.moveTo();
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
      modelFlameGame.moveTo();
    }
  }

  Widget _buildToolPanelWidget(BuildContext context) {
    return Obx(() {
      Project? project = modelProjectController.project.value;
      var children = [
        // CommonAutoSizeText(
        //     modelProjectController.currentSubjectName.value ?? 'unknown'),
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
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  NodeType? addNodeStatus =
                      modelProjectController.addNodeStatus.value;
                  if (addNodeStatus != NodeType.type) {
                    modelProjectController.addNodeStatus.value = NodeType.type;
                  } else {
                    modelProjectController.addNodeStatus.value = null;
                  }
                  modelProjectController.addRelationshipStatus.value = false;
                }
              : null,
          icon: Icon(
            Icons.newspaper_outlined,
            color: modelProjectController.addNodeStatus.value == NodeType.type
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New type node'),
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  NodeType? addNodeStatus =
                      modelProjectController.addNodeStatus.value;
                  if (addNodeStatus != NodeType.image) {
                    modelProjectController.addNodeStatus.value = NodeType.image;
                  } else {
                    modelProjectController.addNodeStatus.value = null;
                  }
                  modelProjectController.addRelationshipStatus.value = false;
                }
              : null,
          icon: Icon(
            Icons.image_outlined,
            color: modelProjectController.addNodeStatus.value == NodeType.image
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New image node'),
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  NodeType? addNodeStatus =
                      modelProjectController.addNodeStatus.value;
                  if (addNodeStatus != NodeType.shape) {
                    modelProjectController.addNodeStatus.value = NodeType.shape;
                  } else {
                    modelProjectController.addNodeStatus.value = null;
                  }
                  modelProjectController.addRelationshipStatus.value = false;
                }
              : null,
          icon: Icon(
            Icons.format_shapes_outlined,
            color: modelProjectController.addNodeStatus.value == NodeType.shape
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New shape node'),
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  NodeType? addNodeStatus =
                      modelProjectController.addNodeStatus.value;
                  if (addNodeStatus != NodeType.remark) {
                    modelProjectController.addNodeStatus.value =
                        NodeType.remark;
                  } else {
                    modelProjectController.addNodeStatus.value = null;
                  }
                  modelProjectController.addRelationshipStatus.value = false;
                }
              : null,
          icon: Icon(
            Icons.comment,
            color: modelProjectController.addNodeStatus.value == NodeType.remark
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New remark node'),
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  modelProjectController.addRelationshipStatus.value =
                      !modelProjectController.addRelationshipStatus.value;
                  modelProjectController.addNodeStatus.value = null;
                }
              : null,
          icon: Icon(
            Icons.link,
            color: modelProjectController.addRelationshipStatus.value
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New relationship'),
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  modelProjectController.selectedRelationship;
                }
              : null,
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
    if (xfile != null) {
      String content = await xfile.readAsString();
      Map<String, dynamic> json = JsonUtil.toJson(content);
      Project project = Project.fromJson(json);
      modelProjectController.project.value = project;
      if (project.subjects.isNotEmpty) {
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
              modelNode =
                  modelProjectController.getModelNode(relationship.dstId);
              if (modelNode == null) {
                subject.remove(relationship);
              }
            }
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Project? project = modelProjectController.project.value;
      List<Widget> rightWidgets = [
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
      var children = [
        _buildToolPanelWidget(context),
        Expanded(
            child: GameWidget(
          key: UniqueKey(),
          game: modelFlameGame,
        ))
      ];
      String title = this.title;
      if (project != null) {
        title = '${AppLocalizations.t(title)}-${project.name}';
      }
      Subject? subject = modelProjectController.getCurrentSubject();
      if (subject != null) {
        title = '$title-${subject.name}';
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
