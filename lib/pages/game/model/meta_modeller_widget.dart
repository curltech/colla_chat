import 'dart:convert';
import 'dart:ui' as ui;

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/base/json_editor.dart';
import 'package:colla_chat/pages/base/json_viewer.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/platform.dart';
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
import 'package:colla_chat/constant/base.dart';

/// 元模型建模器
class MetaModellerWidget extends StatelessWidget with TileDataMixin {
  final JsonViewerWidget jsonViewerWidget = JsonViewerWidget();
  final ModelNodeEditWidget modelNodeEditWidget = ModelNodeEditWidget();

  ModelFlameGame? modelFlameGame;

  MetaModellerWidget({super.key}) {
    indexWidgetProvider.define(modelNodeEditWidget);
    indexWidgetProvider.define(jsonViewerWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'modeller';

  @override
  IconData get iconData => Icons.model_training_outlined;

  @override
  String get title => 'Modeller';

  _selectSubject() async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    List<Option<String>> options = [];
    for (var subject in modelProjectController.project.value!.subjects.values) {
      if (modelProjectController.currentSubjectName.value == subject.name) {
        options.add(Option(subject.name, subject.name, selected: true));
      } else {
        options.add(Option(subject.name, subject.name));
      }
    }
    String? subjectName = await DialogUtil.showSelectDialog<String>(
        title: CommonAutoSizeText(AppLocalizations.t('Select subject')),
        items: options);
    if (subjectName != null) {
      modelProjectController.currentSubjectName.value = subjectName;
      modelFlameGame?.moveTo();
    }
  }

  List<Widget> _buildSubjectButtons() {
    return [
      IconButton(
        onPressed: () async {
          modelProjectController.canAddSubject.value =
              !modelProjectController.canAddSubject.value;
        },
        icon: Icon(
          Icons.electric_meter,
          color: modelProjectController.canAddSubject.value
              ? Colors.yellow
              : myself.primary,
        ),
        tooltip: AppLocalizations.t('New subject'),
      ),
      IconButton(
        onPressed: () async {
          _selectSubject();
        },
        icon: Icon(
          Icons.list_alt_outlined,
          color: myself.primary,
        ),
        tooltip: AppLocalizations.t('Select subject'),
      ),
      IconButton(
        onPressed: () async {
          Project? project = modelProjectController.project.value;
          if (project == null) {
            return;
          }
          String? subjectName =
              modelProjectController.currentSubjectName.value ?? '';
          Subject? subject = project.subjects.remove(subjectName);
          if (subject == null) {
            return;
          }
          subjectName = await DialogUtil.showTextFormField(
              title: AppLocalizations.t('Update subject name'),
              content: subjectName);
          if (subjectName != null) {
            subject.name = subjectName;
            project.subjects[subjectName] = subject;
            modelProjectController.currentSubjectName.value = subjectName;
            subject.subjectComponent?.updateSubjectName();
          }
        },
        icon: Icon(Icons.edit_calendar_outlined, color: myself.primary),
        tooltip: AppLocalizations.t('Update subject name'),
      )
    ];
  }

  List<Widget> _buildMetaNodeButtons() {
    List<Widget> btns = [];
    List<ModelNode>? allowModelNodes =
        modelProjectController.getAllMetaModelNodes();
    if (allowModelNodes == null) {
      return btns;
    }
    for (var allowModelNode in allowModelNodes) {
      String nodeType = allowModelNode.nodeType;
      Widget? btnIcon;
      if (nodeType == NodeType.image.name) {
        if (allowModelNode.content != null) {
          btnIcon = Container(
              color:
                  modelProjectController.canAddModelNode.value == allowModelNode
                      ? Colors.amber
                      : null,
              child: ImageUtil.buildImageWidget(
                  imageContent: allowModelNode.content, width: 24, height: 24));
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
        if (allowModelNode.content != null) {
          btnIcon = btnIcon = Container(
              color:
                  modelProjectController.canAddModelNode.value == allowModelNode
                      ? Colors.amber
                      : null,
              child: ImageUtil.buildImageWidget(
                  imageContent: allowModelNode.content, width: 24, height: 24));
        }
        btnIcon ??= Icon(
          Icons.rectangle_outlined,
          color: modelProjectController.canAddModelNode.value == allowModelNode
              ? Colors.amber
              : myself.primary,
        );
      }

      Widget btn = IconButton(
        onPressed: () {
          _modelNodeAction(allowModelNode);
        },
        icon: btnIcon!,
        tooltip: '${AppLocalizations.t('New')} ${allowModelNode.name}',
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
  }

  List<Widget> _buildRelationshipButtons() {
    List<Widget> btns = [];
    ModelNode? selectedSrcModelNode =
        modelProjectController.selectedSrcModelNode.value;
    ModelNode? selectedDstModelNode =
        modelProjectController.selectedDstModelNode.value;
    if (selectedSrcModelNode == null || selectedDstModelNode == null) {
      return btns;
    }
    String? srcMetaId = selectedSrcModelNode.metaId;
    String? dstMetaId = selectedDstModelNode.metaId;
    if (srcMetaId == null || dstMetaId == null) {
      return btns;
    }
    Set<RelationshipType>? allowRelationshipTypes =
        modelProjectController.getAllAllowRelationshipTypes(
      srcMetaId,
      dstMetaId,
    );
    if (allowRelationshipTypes == null) {
      return btns;
    }
    if (allowRelationshipTypes.contains(RelationshipType.reference)) {
      btns.add(IconButton(
        onPressed: () {
          modelFlameGame?.addRelationship(RelationshipType.reference);
        },
        icon: Icon(
          Icons.linear_scale_outlined,
          color: myself.primary,
        ),
        tooltip: AppLocalizations.t('New reference relationship'),
      ));
    }
    if (allowRelationshipTypes.contains(RelationshipType.association)) {
      btns.add(
        IconButton(
          onPressed: () {
            modelFlameGame?.addRelationship(RelationshipType.association);
          },
          icon: Icon(
            Icons.stacked_line_chart_outlined,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('New association relationship'),
        ),
      );
    }
    if (allowRelationshipTypes.contains(RelationshipType.generalization)) {
      btns.add(
        IconButton(
          onPressed: () {
            modelFlameGame?.addRelationship(RelationshipType.generalization);
          },
          icon: Icon(
            Icons.line_style_outlined,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('New generalization relationship'),
        ),
      );
    }
    if (allowRelationshipTypes.contains(RelationshipType.realization)) {
      btns.add(
        IconButton(
          onPressed: () {
            modelFlameGame?.addRelationship(RelationshipType.realization);
          },
          icon: Icon(
            Icons.line_axis_outlined,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('New realization relationship'),
        ),
      );
    }
    if (allowRelationshipTypes.contains(RelationshipType.dependency)) {
      btns.add(
        IconButton(
          onPressed: () {
            modelFlameGame?.addRelationship(RelationshipType.dependency);
          },
          icon: Icon(
            Icons.line_weight_outlined,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('New dependency relationship'),
        ),
      );
    }
    if (allowRelationshipTypes.contains(RelationshipType.aggregation)) {
      btns.add(
        IconButton(
          onPressed: () {
            modelFlameGame?.addRelationship(RelationshipType.aggregation);
          },
          icon: Icon(
            Icons.blur_linear_outlined,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('New aggregation relationship'),
        ),
      );
    }
    if (allowRelationshipTypes.contains(RelationshipType.composition)) {
      btns.add(
        IconButton(
          onPressed: () {
            modelFlameGame?.addRelationship(RelationshipType.composition);
          },
          icon: Icon(
            Icons.format_line_spacing_outlined,
            color: myself.primary,
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
    ModelNode? modelNode = modelProjectController.selectedSrcModelNode.value;
    if (modelNode != null) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm to delete model node:${modelNode.name}?');
      if (confirm != null && confirm) {
        NodeFrameComponent? nodeFrameComponent = modelNode.nodeFrameComponent;
        if (nodeFrameComponent != null) {
          nodeFrameComponent.subject.modelNodes.remove(modelNode.id);
          nodeFrameComponent.removeFromParent();

          modelFlameGame?.subjectComponent.onUpdate();
        }
      }
      modelProjectController.selectedSrcModelNode.value = null;
      modelProjectController.selectedDstModelNode.value = null;
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

          modelFlameGame?.subjectComponent.onUpdate();
        }
      }
      modelProjectController.selectedRelationship.value = null;
    }
  }

  Widget _buildToolPanelWidget(BuildContext context) {
    return Obx(() {
      List<Widget> btns = [];
      Project? project = modelProjectController.project.value;
      if (project != null) {
        Widget projectWidget;
        if (appDataProvider.secondaryBodyLandscape) {
          projectWidget = Column(
            children: _buildProjectButtons(),
          );
        } else {
          projectWidget = Row(
            children: _buildProjectButtons(),
          );
        }
        btns.add(projectWidget);
        List<Widget> subjectBtns = [..._buildSubjectButtons()];
        String? currentSubjectName =
            modelProjectController.currentSubjectName.value;
        if (currentSubjectName != null) {
          if (modelProjectController.currentSubjectName.value != null) {
            subjectBtns.addAll([
              ..._buildMetaNodeButtons(),
              ..._buildRelationshipButtons(),
              IconButton(
                onPressed: delete,
                icon: Icon(
                  Icons.delete_outline,
                  color: myself.primary,
                ),
                tooltip: AppLocalizations.t('Delete'),
              ),
            ]);
          }
        }
        Widget subjectWidget;
        if (appDataProvider.secondaryBodyLandscape) {
          subjectWidget = Column(
            children: subjectBtns,
          );
        } else {
          subjectWidget = Row(
            children: subjectBtns,
          );
        }
        btns.add(subjectWidget);
      }
      return appDataProvider.secondaryBodyLandscape
          ? Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: btns,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: btns,
            );
    });
  }

  _newProject() async {
    String? projectName = await DialogUtil.showTextFormField(
        title: 'New project',
        content: 'Please input new project name',
        tip: 'unknown');
    if (projectName != null) {
      modelProjectController.currentProject.value =
          Project(projectName, modelProjectController.currentMetaId.value);
      modelProjectController.project.value =
          modelProjectController.currentProject.value;
      modelProjectController.reset();
    }
  }

  _openProject() async {
    XFile? xfile = await FileUtil.selectFile(allowedExtensions: ['json']);
    if (xfile == null) {
      return;
    }
    String content = await xfile.readAsString();
    Project? project;
    try {
      project = await modelProjectController.openProject(content);
    } catch (e) {
      DialogUtil.error(content: e.toString());
    }
    if (project != null) {
      List<ModelNode>? modelNodes =
          modelProjectController.getAllMetaModelNodes();
      if (modelNodes != null && modelNodes.isNotEmpty) {
        for (var modelNode in modelNodes) {
          loadImage(modelNode);
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

  _viewProject() async {
    if (modelProjectController.project.value != null) {
      String content =
          JsonUtil.toJsonString(modelProjectController.project.value);
      jsonContent.value = content;
      indexWidgetProvider.push(jsonViewerWidget.routeName);
    }
  }

  _closeProject() async {
    if (modelProjectController.currentProject.value != null) {
      modelProjectController.currentProject.value = null;
    }
    if (modelProjectController.project.value != null) {
      modelProjectController.project.value = null;
    }
  }

  _viewMetaProject() async {
    Project? metaProject = modelProjectController
        .metaProjects[modelProjectController.currentMetaId.value];
    if (metaProject != null) {
      String content = JsonUtil.toJsonString(metaProject);
      jsonContent.value = content;
      indexWidgetProvider.push(jsonViewerWidget.routeName);
    }
  }

  List<Widget> _buildProjectButtons() {
    List<Widget> btns = [];
    Project? project = modelProjectController.project.value;

    if (project != null) {
      btns.add(IconButton(
        onPressed: () async {
          String? name = await DialogUtil.showTextFormField(
              title: AppLocalizations.t('Update project name'),
              content: project.name);
          if (name != null) {
            project.name = name;
          }
        },
        icon: Icon(Icons.edit, color: myself.primary),
        tooltip: AppLocalizations.t('Update project name'),
      ));
      btns.add(IconButton(
        onPressed: () async {
          await _saveProject();
        },
        icon: Icon(Icons.save, color: myself.primary),
        tooltip: AppLocalizations.t('Save project'),
      ));
      btns.add(IconButton(
        onPressed: () {
          _viewProject();
        },
        icon: Icon(jsonViewerWidget.iconData, color: myself.primary),
        tooltip: AppLocalizations.t('View project'),
      ));
      btns.add(IconButton(
        onPressed: () async {
          _closeProject();
        },
        icon: Icon(Icons.close_outlined, color: myself.primary),
        tooltip: AppLocalizations.t('Close project'),
      ));
    }

    return btns;
  }

  loadImage(ModelNode modelNode) async {
    if ((modelNode.nodeType == NodeType.image.name ||
            modelNode.nodeType == NodeType.image.name) &&
        (modelNode.image == null && modelFlameGame != null)) {
      ui.Image? image;
      if (modelNode.content != null) {
        image = await modelFlameGame!.images
            .fromBase64('${modelNode.name}.png', modelNode.content!);
      }
      image ??= await modelFlameGame!.images.load('colla.png');
      modelNode.image = image;
    }
  }

  _registerMetaProject() async {
    XFile? xfile = await FileUtil.selectFile(allowedExtensions: ['json']);
    if (xfile == null) {
      return;
    }
    String content = await xfile.readAsString();

    await modelProjectController.registerMetaProject(content);
  }

  _register() async {
    Project? project = modelProjectController.project.value;
    if (project != null) {
      project.meta = true;
      String content = JsonUtil.toJsonString(project);

      await modelProjectController.registerMetaProject(content);
    }
  }

  _selectMetaProject() async {
    List<Option<String>> options = [];
    for (var metaProject in modelProjectController.metaProjects.value.values) {
      if (modelProjectController.currentMetaId.value == metaProject.id) {
        options.add(Option(
          metaProject.name,
          metaProject.id,
          selected: true,
        ));
      } else {
        options.add(Option(metaProject.name, metaProject.id));
      }
    }
    String? metaId = await DialogUtil.showSelectDialog<String>(
        title: const CommonAutoSizeText('Select meta project'), items: options);
    if (metaId != null) {
      modelProjectController.currentMetaId.value = metaId;
      modelProjectController.project.value = null;
    }
  }

  List<Widget> _buildMetaProjectButtons() {
    Project? metaProject = modelProjectController
        .metaProjects[modelProjectController.currentMetaId.value];
    Project? project = modelProjectController.project.value;
    List<Widget> btns = [];

    btns.add(
      IconButton(
        onPressed: () {
          _registerMetaProject();
        },
        icon: const Icon(Icons.open_in_browser_outlined),
        tooltip: AppLocalizations.t('Register meta project'),
      ),
    );
    if (project != null) {
      btns.add(
        IconButton(
          onPressed: () {
            _register();
          },
          icon: const Icon(Icons.app_registration),
          tooltip: AppLocalizations.t('Register current project'),
        ),
      );
    }
    if (modelProjectController.metaProjects.isNotEmpty) {
      btns.add(IconButton(
        onPressed: () {
          _selectMetaProject();
        },
        icon: const Icon(Icons.select_all_outlined),
        tooltip: AppLocalizations.t('Select meta project'),
      ));
    }
    if (metaProject != null) {
      btns.add(IconButton(
        onPressed: () {
          _viewMetaProject();
        },
        icon: const Icon(Icons.margin),
        tooltip: AppLocalizations.t('View meta project'),
      ));
    }

    return btns;
  }

  Widget _buildToggleButtons() {
    final List<bool> isSelected = <bool>[
      modelProjectController.project.value ==
          modelProjectController.currentProject.value,
      modelProjectController.project.value ==
          modelProjectController
              .metaProjects[modelProjectController.currentMetaId.value],
    ];
    return ToggleButtons(
      borderRadius: borderRadius,
      renderBorder: false,
      color: Colors.grey,
      fillColor: myself.primary,
      selectedColor: Colors.white,
      isSelected: isSelected,
      onPressed: (int newIndex) {
        if (newIndex == 0) {
          modelProjectController.project.value =
              modelProjectController.currentProject.value;
        } else if (newIndex == 1) {
          modelProjectController.project.value = modelProjectController
              .metaProjects[modelProjectController.currentMetaId.value];
        }
      },
      children: <Widget>[
        Tooltip(
            message: AppLocalizations.t('Current project'),
            child: Icon(Icons.stay_current_landscape)),
        Tooltip(
            message: AppLocalizations.t('Meta project'),
            child: Icon(Icons.stay_current_portrait)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Project? metaProject = modelProjectController
          .metaProjects.value[modelProjectController.currentMetaId.value];
      Project? project = modelProjectController.project.value;
      List<Widget> rightWidgets = [
        ..._buildMetaProjectButtons(),
        IconButton(
          onPressed: () {
            _newProject();
          },
          icon: Icon(Icons.newspaper_sharp),
          tooltip: AppLocalizations.t('New project'),
        ),
        IconButton(
          onPressed: () {
            _openProject();
          },
          icon: Icon(Icons.file_open),
          tooltip: AppLocalizations.t('Open project'),
        ),
        _buildToggleButtons(),
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
      if (metaProject != null) {
        title = '$title\n${metaProject.name}';
      }
      if (project != null) {
        title = '$title\n${project.name}';
      }
      Widget titleWidget = CommonAutoSizeText(
        AppLocalizations.t(title ?? ''),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        wrapWords: false,
        overflow: TextOverflow.visible,
      );
      return ListenableBuilder(
          listenable: appDataProvider,
          builder: (BuildContext context, Widget? _) {
            return AppBarView(
                titleWidget: titleWidget,
                helpPath: routeName,
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
