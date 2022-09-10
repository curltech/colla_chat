import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../entity/base.dart';
import '../../l10n/localization.dart';
import 'column_field_widget.dart';

class FormInputController with ChangeNotifier {
  final List<ColumnFieldDef> columnFieldDefs;
  final Map<String, ColumnFieldController> controllers = {};
  EntityState? state;

  FormInputController(this.columnFieldDefs, {this.state});

  setController(String name, ColumnFieldController controller) {
    controllers[name] = controller;
  }

  clear() {
    for (var controller in controllers.values) {
      controller.clear();
    }
  }

  _adjustValues(Map<String, dynamic> values) {
    for (var columnFieldDef in columnFieldDefs) {
      String name = columnFieldDef.name;
      if (values.containsKey(name)) {
        DataType dataType = columnFieldDef.dataType;
        dynamic value = values[name];
        if (value == null) {
          continue;
        }
        if (value is String && dataType == DataType.string) {
          continue;
        }
        if (value is String && dataType != DataType.string) {
          var v = StringUtil.toObject(value, dataType);
          if (v == null) {
            values.remove(name);
          } else {
            values[name] = v;
          }
        }
      }
    }
  }

  //获取值，先找文本框
  dynamic getValue(String name) {
    var controller = controllers[name];
    if (controller != null) {
      return controller.value;
    }
  }

  //所有值，合并文本框和非文本框
  dynamic getValues() {
    Map<String, dynamic> values = {};
    for (var entry in controllers.entries) {
      String name = entry.key;
      values[name] = entry.value.value;
      if (state == null) {
        bool changed = entry.value.changed;
        if (changed) {
          state = EntityState.update;
        }
      }
    }
    if (state != null) {
      values['state'] = state;
    }
    _adjustValues(values);

    return values;
  }

  ///内部改变值
  changeValue(String name, dynamic value) {
    var controller = controllers[name];
    if (controller != null) {
      controller.value = value;
    }
  }

  ///外部设置值
  setValue(String name, dynamic value) {
    var controller = controllers[name];
    if (controller != null) {
      controller.value = value;
    }
  }

  setValues(Map<String, dynamic> values) {
    for (var entry in controllers.entries) {
      var name = entry.key;
      var value = values[name];
      var controller = entry.value;
      if (controller.value != value) {
        controller.value = value;
      }
    }
  }

  ///外部设置值
  setMode(String name, ColumnFieldMode mode) {
    var controller = controllers[name];
    if (controller != null) {
      controller.mode = mode;
    }
  }
}

class FormInputWidget extends StatelessWidget {
  final Map<String, dynamic>? initValues;
  late final FormInputController controller;

  final Function(Map<String, dynamic>) onOk;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;

  FormInputWidget(
      {Key? key,
      required List<ColumnFieldDef> columnFieldDefs,
      this.initValues,
      required this.onOk,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.spacing = 0.0})
      : super(key: key) {
    controller = FormInputController(columnFieldDefs);
    if (initValues != null) {
      var state = initValues!['state'];
      if (state != null) {
        controller.state = state;
      }
    }
  }

  Widget _build(BuildContext context) {
    FormInputController controller = Provider.of<FormInputController>(context);
    List<Widget> children = [];
    for (var columnFieldDef in controller.columnFieldDefs) {
      children.add(SizedBox(
        height: spacing,
      ));
      String name = columnFieldDef.name;
      dynamic initValue;
      if (initValues != null) {
        initValue = initValues![name];
      }
      Widget columnFieldWidget = ColumnFieldWidget(
        columnFieldDef: columnFieldDef,
        initValue: initValue,
        mode: ColumnFieldMode.edit,
      );
      children.add(columnFieldWidget);
    }
    children.add(const SizedBox(
      height: 30.0,
    ));
    children.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
          child: Text(AppLocalizations.t('Ok')),
          onPressed: () {
            var values = controller.getValues();
            onOk(values);
          },
        ),
        TextButton(
          child: Text(AppLocalizations.t('Reset')),
          onPressed: () {
            controller.clear();
          },
        )
      ]),
    ));
    return Column(mainAxisAlignment: mainAxisAlignment, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        builder: (BuildContext context, Widget? child) {
      return _build(context);
    }, create: (BuildContext context) {
      return controller;
    });
  }
}
