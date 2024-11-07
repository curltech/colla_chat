import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttributeEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'attribute_edit';

  @override
  IconData get iconData => Icons.edit_attributes_outlined;

  @override
  String get title => 'AttributeEdit';

  ModelNode? get modelNode {
    return modelProjectController.selectedModelNode.value;
  }

  final Rx<List<Attribute>?> attributes = Rx<List<Attribute>?>(null);

  final Rx<Attribute?> attribute = Rx<Attribute?>(null);

  AttributeEditWidget({super.key});

  final List<PlatformDataField> attributeDataFields = [
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
    PlatformDataField(
        name: 'scope',
        label: 'Scope',
        prefixIcon: Icon(Icons.shopping_bag_outlined, color: myself.primary)),
  ];

  late final FormInputController formInputController =
      FormInputController(attributeDataFields);

  Widget _buildAttributesWidget(BuildContext context) {
    return Obx(() {
      if (attributes.value != null && attributes.value!.isNotEmpty) {
        List<TileData> tiles = [];
        for (var attribute in attributes.value!) {
          TileData tile = TileData(
              title: attribute.name,
              titleTail: attribute.dataType,
              selected: this.attribute.value == attribute);
          tiles.add(tile);
        }

        return DataListView(
          itemCount: tiles.length,
          itemBuilder: (BuildContext context, int index) {
            return tiles[index];
          },
          onTap: (int index, String title,
              {TileData? group, String? subtitle}) {
            attribute.value = attributes.value![index];
          },
        );
      }

      return nilBox;
    });
  }

  //ModelNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    List<Option<dynamic>> options = [];
    for (var value in DataType.values) {
      options.add(Option(value.name, value.name));
    }
    attributeDataFields.add(PlatformDataField(
        name: 'dataType',
        label: 'DataType',
        prefixIcon: Icon(Icons.data_object_outlined, color: myself.primary),
        inputType: InputType.togglebuttons,
        options: options));
    return Obx(() {
      if (attribute.value == null) {
        return nilBox;
      }
      formInputController.setValues(JsonUtil.toJson(attribute.value));
      var formInputWidget = FormInputWidget(
        spacing: 15.0,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController,
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: formInputWidget,
      );
    });
  }

  Attribute? _onOk(Map<String, dynamic> values) {
    Attribute current = Attribute.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has attribute name'));
      return null;
    }
    if (StringUtil.isEmpty(current.scope)) {
      DialogUtil.error(content: AppLocalizations.t('Must has attribute scope'));
      return null;
    }
    if (StringUtil.isEmpty(current.dataType)) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has attribute dataType'));
      return null;
    }
    attribute.value?.name = current.name;
    attribute.value?.scope = current.scope;
    attribute.value?.dataType = current.dataType;
    _onUpdate();
    DialogUtil.info(
        content: 'Successfully update attribute:${attribute.value!.name}');

    return current;
  }

  Future<void> _onAdd() async {
    PositionComponent? child = modelNode?.nodeFrameComponent?.child;
    if (child != null) {
      attribute.value = Attribute('unknownAttribute');
      if (attributes.value != null) {
        attributes.value!.add(attribute.value!);
        if (child is TypeNodeComponent) {
          child.attributeAreaComponent.onAdd(attribute.value!);
        }
      }
    }
  }

  Future<void> _onDelete() async {
    bool? success = await DialogUtil.confirm(
        content:
            'Do you confirm to delete this attribute:${attribute.value?.name}');
    if (success != null && success) {
      List<Attribute>? attributes = modelNode?.attributes;
      if (attributes != null && attributes.isNotEmpty) {
        attributes.remove(attribute.value);
        AttributeTextComponent? attributeTextComponent =
            attribute.value?.attributeTextComponent;

        if (attributeTextComponent != null) {
          attributeTextComponent.onDelete();
        }
        attribute.value = null;
      }
    }
  }

  Future<void> _onUpdate() async {
    if (attribute.value != null) {
      AttributeTextComponent? attributeTextComponent =
          attribute.value?.attributeTextComponent;

      if (attributeTextComponent != null) {
        attributeTextComponent.onUpdate();
      }
    }
  }

  List<Widget> _buildRightButton(BuildContext context) {
    return [
      IconButton(
        tooltip: AppLocalizations.t('Add attribute'),
        icon: const Icon(Icons.add),
        onPressed: () {
          _onAdd();
        },
      ),
      IconButton(
        tooltip: AppLocalizations.t('Delete attribute'),
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          _onDelete();
        },
      ),
      IconButton(
        tooltip: AppLocalizations.t('Update attribute'),
        icon: const Icon(Icons.update),
        onPressed: () {
          _onUpdate();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    attributes.value = modelNode?.attributes;

    Widget listenable = ListenableBuilder(
        listenable: appDataProvider,
        builder: (BuildContext context, Widget? _) {
          Widget child;
          if (appDataProvider.secondaryBodyLandscape) {
            child =
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: appDataProvider.secondaryBodyWidth * 0.4,
                  child: _buildAttributesWidget(context)),
              const VerticalDivider(),
              Expanded(child: _buildFormInputWidget(context))
            ]);
          } else {
            child = Column(children: [
              SizedBox(
                  height: appDataProvider.portraitSize.height * 0.4,
                  child: _buildAttributesWidget(context)),
              const Divider(),
              Expanded(child: _buildFormInputWidget(context))
            ]);
          }
          return child;
        });

    return AppBarView(
        title: title,
        withLeading: true,
        rightWidgets: _buildRightButton(context),
        child: listenable);
  }
}
