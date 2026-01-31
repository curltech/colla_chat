import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';

class NodeRelationshipEditWidget extends StatelessWidget with DataTileMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'relationship_edit';

  @override
  IconData get iconData => Icons.link;

  @override
  String get title => 'RelationshipEdit';

  NodeRelationshipEditWidget({super.key});

  NodeRelationship? get nodeRelationship {
    return modelProjectController.selectedRelationship.value;
  }

  final List<PlatformDataField> relationshipDataFields = [
    PlatformDataField(
        name: 'srcId',
        label: 'SrcId',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'dstId',
        label: 'DstId',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'srcCardinality',
        label: 'SrcCardinality',
        dataType: DataType.int,
        prefixIcon: Icon(Icons.star, color: myself.primary)),
    PlatformDataField(
        name: 'dstCardinality',
        label: 'DstCardinality',
        dataType: DataType.int,
        prefixIcon: Icon(Icons.star, color: myself.primary)),
  ];

  PlatformReactiveFormController? platformReactiveFormController;

  //ModelNode信息编辑界面
  Widget _buildPlatformReactiveForm(BuildContext context) {
    List<Option<dynamic>> options = [];
    for (var value in RelationshipType.values) {
      options.add(Option(value.name, value.name));
    }
    List<PlatformDataField> relationshipDataFields = [
      ...this.relationshipDataFields
    ];
    relationshipDataFields.add(PlatformDataField(
        name: 'relationshipType',
        label: 'RelationshipType',
        readOnly: true,
        prefixIcon: Icon(Icons.link, color: myself.primary),
        inputType: InputType.toggleButtons,
        options: options));
    relationshipDataFields.add(PlatformDataField(
        name: 'allowRelationshipTypes',
        label: 'AllowRelationshipTypes',
        prefixIcon: Icon(Icons.link, color: myself.primary),
        dataType: DataType.list,
        inputType: InputType.checkbox,
        options: options));
    platformReactiveFormController =
        PlatformReactiveFormController(relationshipDataFields);
    platformReactiveFormController!.values = JsonUtil.toJson(nodeRelationship);
    var formInputWidget = PlatformReactiveForm(
      spacing: 15.0,
      onSubmit: (Map<String, dynamic> values) {
        _onOk(values);
      },
      platformReactiveFormController: platformReactiveFormController!,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: formInputWidget,
    );
  }

  NodeRelationship? _onOk(Map<String, dynamic> values) {
    NodeRelationship current = NodeRelationship.fromJson(values);
    if (StringUtil.isEmpty(current.relationshipType)) {
      DialogUtil.error(
          content:
              AppLocalizations.t('Must has nodeRelationship relationshipType'));
      return null;
    }
    // if (current.srcCardinality == null) {
    //   DialogUtil.error(
    //       content:
    //           AppLocalizations.t('Must has nodeRelationship srcCardinality'));
    //   return null;
    // }
    // if (current.dstCardinality == null) {
    //   DialogUtil.error(
    //       content:
    //           AppLocalizations.t('Must has nodeRelationship dstCardinality'));
    //   return null;
    // }
    nodeRelationship?.relationshipType = current.relationshipType;
    nodeRelationship?.srcCardinality = current.srcCardinality;
    nodeRelationship?.dstCardinality = current.dstCardinality;
    nodeRelationship?.allowRelationshipTypes = current.allowRelationshipTypes;
    DialogUtil.info(content: 'Successfully update nodeRelationship');

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: true,
        child: _buildPlatformReactiveForm(context));
  }
}
