import 'dart:typed_data';

import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/localization.dart';
import 'form_input_widget.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum InputType { label, text, password, radio, checkbox, select, textarea }

/// 通用列表项的数据模型
class InputFieldDef {
  final String name;
  final String label;
  final InputType inputType;
  String initValue;

  //图标
  final Widget? prefixIcon;

  //头像
  final String? avatar;

  final String? hintText;

  final TextInputType? textInputType;

  final Widget? suffixIcon;

  final int? maxLines;

  bool readOnly;

  final List<Option>? options;

  final Function(String value)? validator;

  final bool autoValidate;

  InputFieldDef({
    required this.name,
    required this.label,
    this.inputType = InputType.text,
    this.initValue = '',
    this.prefixIcon,
    this.avatar,
    this.hintText,
    this.textInputType = TextInputType.text,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.options,
    this.validator,
    this.autoValidate = false,
  });
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class InputFieldWidget extends StatelessWidget {
  final InputFieldDef inputFieldDef;

  const InputFieldWidget({Key? key, required this.inputFieldDef})
      : super(key: key);

  dynamic _getValue(BuildContext context, InputFieldDef inputDef) {
    final name = inputDef.name;
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    dynamic value = formInputController.getValue(name);
    value = value ?? inputDef.initValue;
    value = value ?? '';

    return value;
  }

  Widget? _buildLabel(BuildContext context, InputFieldDef inputDef) {
    final label = inputDef.label;
    dynamic value = _getValue(context, inputDef);

    return Text(AppLocalizations.t(label) + ':' + value);
  }

  Widget? _buildIcon(InputFieldDef inputDef) {
    Widget? icon;
    final avatar = inputDef.avatar;
    if (inputDef.prefixIcon != null) {
      icon = inputDef.prefixIcon;
    } else if (avatar != null) {
      icon = Image.memory(Uint8List.fromList(avatar.codeUnits));
    }

    return icon;
  }

  Widget _buildTextFormField(BuildContext context, InputFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var controller = TextEditingController();
    controller.text = _getValue(context, inputDef);
    formInputController.initController(inputDef.name, controller);
    var widget = TextFormField(
      controller: controller,
      keyboardType: inputFieldDef.textInputType,
      maxLines: inputFieldDef.maxLines,
      readOnly: inputFieldDef.readOnly,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(inputDef.label),
          prefixIcon: _buildIcon(inputDef),
          suffixIcon: inputFieldDef.suffixIcon,
          hintText: inputDef.hintText),
    );

    return widget;
  }

  Widget _buildPasswordField(BuildContext context, InputFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    bool? pwdShow = formInputController.getFlag(inputDef.name);
    pwdShow ??= false;
    var controller = TextEditingController();
    controller.text = _getValue(context, inputDef);
    formInputController.initController(inputDef.name, controller);
    var widget = TextFormField(
      controller: controller,
      keyboardType: inputFieldDef.textInputType,
      obscureText: !pwdShow,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(inputDef.label),
          prefixIcon: _buildIcon(inputDef),
          suffixIcon: IconButton(
            icon: Icon(pwdShow ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              formInputController.changeFlag(inputDef.name, !pwdShow!);
            },
          ),
          hintText: inputDef.hintText),
    );
    return widget;
  }

  Widget _buildRadioField(BuildContext context, InputFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var options = inputDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var radio = Radio<String>(
          onChanged: (String? value) {
            formInputController.setValue(inputDef.name, value);
          },
          value: option.value,
          groupValue: _getValue(context, inputDef),
        );
        var row = Row(
          children: [radio, Text(option.label)],
        );
        children.add(row);
      }
    }

    return Column(children: children);
  }

  Widget _buildCheckboxField(BuildContext context, InputFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var options = inputDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        Set<String>? value = _getValue(context, inputDef);
        value ??= <String>{};
        var checkbox = Checkbox(
          onChanged: (bool? selected) {
            if (value != null) {
              if (selected == null || !selected) {
                value.remove(option.value);
              } else if (selected) {
                value.add(option.value);
              }
            }
            formInputController.setValue(inputDef.name, value);
          },
          value: value.contains(option.value),
        );
        var row = Row(
          children: [checkbox, Text(option.label)],
        );
        children.add(row);
      }
    }

    return Column(children: children);
  }

  Widget _buildSwitchField(BuildContext context, InputFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var options = inputDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        Set<String>? value = _getValue(context, inputDef);
        value ??= <String>{};
        var checkbox = Switch(
          onChanged: (bool? selected) {
            if (value != null) {
              if (selected == null || !selected) {
                value.remove(option.value);
              } else if (selected) {
                value.add(option.value);
              }
            }
            formInputController.setValue(inputDef.name, value);
          },
          value: value.contains(option.value),
        );
        var row = Row(
          children: [checkbox, Text(option.label)],
        );
        children.add(row);
      }
    }

    return Column(children: children);
  }

  Widget _buildDropdownButton(BuildContext context, InputFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var options = inputDef.options;
    List<DropdownMenuItem<String>> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = DropdownMenuItem(
          value: option.value,
          child: Text(option.label),
        );
        children.add(item);
      }
    }
    var dropdownButton = DropdownButton<String>(
      items: children,
      onChanged: (String? value) {
        formInputController.setValue(inputDef.name, value);
      },
    );

    return dropdownButton;
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;
    var inputType = inputFieldDef.inputType;
    switch (inputType) {
      case InputType.text:
        widget = _buildTextFormField(context, inputFieldDef);
        break;
      case InputType.password:
        widget = _buildPasswordField(context, inputFieldDef);
        break;
      default:
        widget = _buildTextFormField(context, inputFieldDef);
    }
    return widget;
  }
}
