import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/localization.dart';
import '../../tool/util.dart';
import 'input_field_widget.dart';

class FormInputController with ChangeNotifier {
  //非文本框的值
  Map<String, dynamic> values = {};
  final Map<String, dynamic> flags = {};

  //文本框的值
  final Map<String, TextEditingController> controllers = {};

  FormInputController();

  initController(String name, TextEditingController controller) {
    controllers[name] = controller;
  }

  clear() {
    values.clear();
    flags.clear();
    for (var controller in controllers.values) {
      controller.clear();
    }
  }

  //获取值，先找文本框
  dynamic getValue(String name) {
    var controller = controllers[name];
    if (controller != null) {
      return controller.text;
    } else {
      return values[name];
    }
  }

  //所有值，合并文本框和非文本框
  dynamic getValues() {
    Map<String, dynamic> values = {};
    values.addAll(this.values);
    for (var entry in controllers.entries) {
      String name = entry.key;
      values[name] = entry.value.text;
    }
    return values;
  }

  ///内部改变值
  changeValue(String name, dynamic value) {
    var controller = controllers[name];
    if (controller != null) {
      controller.text = value;
    } else {
      values[name] = value;
      notifyListeners();
    }
  }

  ///外部设置值
  setValue(String name, dynamic value) {
    var controller = controllers[name];
    if (controller != null) {
      controller.text = value;
    } else {
      values[name] = value;
      notifyListeners();
    }
  }

  setValues(Map<String, dynamic> values) {
    for (var entry in values.entries) {
      var name = entry.key;
      var value = entry.value;
      var controller = controllers[name];
      if (controller != null) {
        controller.text = value;
      } else {
        values[name] = value;
      }
    }
    if (values.isNotEmpty) {
      notifyListeners();
    }
  }

  dynamic getFlag(String name) {
    return flags[name];
  }

  changeFlag(String name, dynamic flag) {
    if (flags[name] != flag) {
      flags[name] = flag;
      notifyListeners();
    }
  }
}

class FormInputWidget extends StatelessWidget {
  //格式定义
  final List<InputFieldDef> inputFieldDefs;
  final Map<String, dynamic>? initValues;
  final FormInputController controller = FormInputController();
  final Function(Map<String, dynamic>) onOk;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;

  FormInputWidget(
      {Key? key,
      required this.inputFieldDefs,
      this.initValues,
      required this.onOk,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.spacing = 0.0})
      : super(key: key);

  _adjustValues(Map<String, dynamic> values) {
    for (var inputFieldDef in inputFieldDefs) {
      String name = inputFieldDef.name;
      if (values.containsKey(name)) {
        DataType dataType = inputFieldDef.dataType;
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

  Widget _build(BuildContext context) {
    FormInputController controller = Provider.of<FormInputController>(context);
    List<Widget> children = [];
    for (var inputFieldDef in inputFieldDefs) {
      children.add(SizedBox(
        height: spacing,
      ));
      String name = inputFieldDef.name;
      dynamic initValue;
      if (initValues != null) {
        initValue = initValues![name];
      }
      Widget inputFieldWidget =
          InputFieldWidget(inputFieldDef: inputFieldDef, initValue: initValue);
      children.add(inputFieldWidget);
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
            _adjustValues(values);
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
