import 'dart:typed_data';

import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/localization.dart';
import 'form_input_widget.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum InputType {
  label,
  text,
  password,
  radio,
  checkbox,
  select,
  textarea,
  date,
  time
}

enum DataType { int, double, string, bool, date, set, list, map }

/// 通用列表项的数据模型
class ColumnFieldDef {
  final String name;
  final String label;
  final InputType inputType;
  final DataType dataType;
  dynamic initValue;

  //图标
  final Widget? prefixIcon;

  //头像
  final String? avatar;

  final String? hintText;

  final TextInputType? textInputType;

  final Widget? suffixIcon;

  final bool cancel;

  final int? maxLines;

  bool readOnly;

  final List<Option>? options;

  final Function(String value)? validator;

  final bool autoValidate;

  Function(int, bool)? onSort;

  ColumnFieldDef(
      {required this.name,
      required this.label,
      this.inputType = InputType.text,
      this.dataType = DataType.string,
      this.initValue = '',
      this.prefixIcon,
      this.avatar,
      this.hintText,
      this.textInputType = TextInputType.text,
      this.suffixIcon,
      this.cancel = false,
      this.maxLines = 1,
      this.readOnly = false,
      this.options,
      this.validator,
      this.autoValidate = false,
      this.onSort});
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class InputFieldWidget extends StatelessWidget {
  final ColumnFieldDef inputFieldDef;
  final dynamic initValue;

  const InputFieldWidget(
      {Key? key, required this.inputFieldDef, this.initValue})
      : super(key: key);

  dynamic _getInitValue(BuildContext context, ColumnFieldDef inputDef) {
    var dataType = inputDef.dataType;
    dynamic v = initValue ?? inputDef.initValue;
    if (dataType == DataType.set ||
        dataType == DataType.list ||
        dataType == DataType.map) {
      return v;
    }
    if (v == null) {
      return '';
    }
    if (dataType == DataType.date) {
      var d = v as DateTime;
      return d.toUtc().toIso8601String();
    }
    return v.toString();
  }

  Widget? _buildLabel(BuildContext context, ColumnFieldDef inputDef) {
    final label = inputDef.label;
    dynamic value = _getInitValue(context, inputDef);

    return Text(value);
  }

  Widget? _buildIcon(ColumnFieldDef inputDef) {
    Widget? icon;
    final avatar = inputDef.avatar;
    if (inputDef.prefixIcon != null) {
      icon = inputDef.prefixIcon;
    } else if (avatar != null) {
      icon = Image.memory(Uint8List.fromList(avatar.codeUnits));
    }

    return icon;
  }

  Widget _buildTextFormField(BuildContext context, ColumnFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var controller = TextEditingController();
    var value = _getInitValue(context, inputDef);
    controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(TextPosition(
            offset: value.length, affinity: TextAffinity.downstream)));
    formInputController.initController(inputDef.name, controller);
    Widget? suffix;
    if (inputFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.cancel, color: Colors.grey))
          : null;
    }
    var widget = TextFormField(
      controller: controller,
      keyboardType: inputFieldDef.textInputType,
      maxLines: inputFieldDef.maxLines,
      readOnly: inputFieldDef.readOnly,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(inputDef.label),
          prefixIcon: _buildIcon(inputDef),
          suffixIcon: inputFieldDef.suffixIcon,
          suffix: suffix,
          hintText: inputDef.hintText),
    );

    return widget;
  }

  Widget _buildPasswordField(BuildContext context, ColumnFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    bool? pwdShow = formInputController.getFlag(inputDef.name);
    pwdShow ??= false;
    var controller = TextEditingController();
    var value = _getInitValue(context, inputDef);
    controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(TextPosition(
            offset: value.length, affinity: TextAffinity.downstream)));
    formInputController.initController(inputDef.name, controller);
    Widget? suffix;
    if (inputFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.cancel, color: Colors.grey))
          : null;
    }
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
          suffix: suffix,
          hintText: inputDef.hintText),
    );
    return widget;
  }

  Widget _buildRadioField(BuildContext context, ColumnFieldDef inputDef) {
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
          groupValue: _getInitValue(context, inputDef),
        );
        var row = Row(
          children: [radio, Text(option.label)],
        );
        children.add(row);
      }
    }

    return Column(children: children);
  }

  Widget _buildCheckboxField(BuildContext context, ColumnFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var options = inputDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        Set<String>? value = _getInitValue(context, inputDef);
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

  Widget _buildSwitchField(BuildContext context, ColumnFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var options = inputDef.options;
    List<Widget> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        Set<String>? value = _getInitValue(context, inputDef);
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

  Widget _buildDropdownButton(BuildContext context, ColumnFieldDef inputDef) {
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

  Widget _buildInputDate(BuildContext context, ColumnFieldDef inputDef) {
    FormInputController formInputController =
        Provider.of<FormInputController>(context);
    var controller = TextEditingController();
    var value = _getInitValue(context, inputDef);
    controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.fromPosition(TextPosition(
            offset: value.length, affinity: TextAffinity.downstream)));
    formInputController.initController(inputDef.name, controller);
    Widget? suffix;
    if (inputFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.cancel, color: Colors.grey))
          : null;
    }
    var widget = TextFormField(
      controller: controller,
      keyboardType: inputFieldDef.textInputType,
      readOnly: true,
      decoration: InputDecoration(
          labelText: AppLocalizations.t(inputDef.label),
          prefixIcon: _buildIcon(inputDef),
          suffixIcon:
              IconButton(icon: const Icon(Icons.date_range), onPressed: () {}),
          suffix: suffix,
          hintText: inputDef.hintText),
    );

    return widget;
  }

  _showDatePicker(BuildContext context, TextEditingController controller) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      // 初始化选中日期
      firstDate: DateTime(2018, 6),
      // 开始日期
      lastDate: DateTime(2025, 6),
      // 结束日期
      currentDate: DateTime(2020, 10, 20),
      // 当前日期
      helpText: "helpText",
      // 左上方提示
      cancelText: "cancelText",
      // 取消按钮文案
      confirmText: "confirmText", // 确认按钮文案
    ).then((value) {
      if (value != null) {
        controller.text = value.toUtc().toIso8601String();
      }
    });
  }

  _showDatePickerInput(BuildContext context) {
    showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        // 初始化选中日期
        firstDate: DateTime(2020, 6),
        // 开始日期
        lastDate: DateTime(2021, 6),
        // 结束日期
        initialEntryMode: DatePickerEntryMode.input,
        // 日历弹框样式

        textDirection: TextDirection.ltr,
        // 文字方向

        currentDate: DateTime(2020, 10, 20),
        // 当前日期
        helpText: "helpText",
        // 左上方提示
        cancelText: "cancelText",
        // 取消按钮文案
        confirmText: "confirmText",
        // 确认按钮文案

        errorFormatText: "errorFormatText",
        // 格式错误提示
        errorInvalidText: "errorInvalidText",
        // 输入不在 first 与 last 之间日期提示

        fieldLabelText: "fieldLabelText",
        // 输入框上方提示
        fieldHintText: "fieldHintText",
        // 输入框为空时内部提示

        initialDatePickerMode: DatePickerMode.day,
        // 日期选择模式，默认为天数选择
        useRootNavigator: true,
        // 是否为根导航器
        // 设置不可选日期，这里将 2020-10-15，2020-10-16，2020-10-17 三天设置不可选
        selectableDayPredicate: (dayTime) {
          if (dayTime == DateTime(2020, 10, 15) ||
              dayTime == DateTime(2020, 10, 16) ||
              dayTime == DateTime(2020, 10, 17)) {
            return false;
          }
          return true;
        });
  }

  CalendarDatePicker _calendarDatePicker(DatePickerMode mode) {
    return CalendarDatePicker(
        initialDate: DateTime.now(), // 初始化选中日期
        currentDate: DateTime(2020, 10, 18),
        firstDate: DateTime(2020, 9, 10), // 开始日期
        lastDate: DateTime(2022, 9, 10), // 结束日期
        initialCalendarMode: mode, // 日期选择样式
        // 选中日期改变回调函数
        onDateChanged: (dateTime) {
          logger.i("onDateChanged $dateTime");
        },
        // 月份改变回调函数
        onDisplayedMonthChanged: (dateTime) {
          logger.i("onDisplayedMonthChanged $dateTime");
        },
        // 筛选日期可不可点回调函数
        selectableDayPredicate: (dayTime) {
          if (dayTime == DateTime(2020, 10, 15) ||
              dayTime == DateTime(2020, 10, 16) ||
              dayTime == DateTime(2020, 10, 17)) {
            return false;
          }
          return true;
        });
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
