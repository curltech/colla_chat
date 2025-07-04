import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/base/color_picker.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:toggle_switch/toggle_switch.dart';

///存储字段的真实值和文本显示值
class DataFieldController with ChangeNotifier {
  final PlatformDataField dataField;

  //非文本框的值
  dynamic _value;
  dynamic _flag;
  bool _changed = false;

  //文本框的时候是TextEditingController，其他的时候是普通的ValueNotifier
  ValueNotifier<dynamic>? controller;

  DataFieldController(
    this.dataField, {
    dynamic value,
    dynamic flag,
    this.controller,
  }) {
    _value = value;
    _flag = flag;
  }

  ///获取真实值，如果控制器为空，返回_value，否则取控制器的值，并覆盖_value
  dynamic get value {
    if (controller != null) {
      if (dataField.inputType == InputType.text ||
          dataField.inputType == InputType.textarea ||
          dataField.inputType == InputType.password) {
        String valueStr = (controller as TextEditingController).text;
        if (valueStr.isNotEmpty) {
          if (dataField.dataType == DataType.int) {
            _value = int.parse(valueStr);
          } else if (dataField.dataType == DataType.double) {
            _value = double.parse(valueStr);
          } else if (dataField.dataType == DataType.string) {
            _value = (controller as TextEditingController).text;
          }
        } else {
          _value = null;
        }
      }
    }
    return _value;
  }

  ///设置真实值，如果控制器为空，设置_value，否则设置控制器的值，并设置_value
  set value(dynamic value) {
    var realValue = value;
    String valueStr = '';
    if (controller != null) {
      if (value != null) {
        if (value is DateTime &&
            (dataField.inputType == InputType.datetime ||
                dataField.inputType == InputType.date)) {
          valueStr = value.toLocal().toIso8601String();
          realValue = value.toUtc().toIso8601String();
        } else if (value is TimeOfDay &&
            dataField.inputType == InputType.time) {
          valueStr = value.toString();
          realValue = value.toString();
        } else {
          valueStr = value.toString();
        }
      } else {
        valueStr = '';
        realValue = null;
      }
    }
    if (_value != realValue) {
      _value = realValue;
      _changed = true;
    }
    if (controller != null) {
      if (controller is TextEditingController) {
        String v = (controller as TextEditingController).text;
        if (valueStr != v) {
          (controller as TextEditingController).text = valueStr;
          _changed = true;
        }
      } else {
        dynamic v = controller!.value;
        if (valueStr != v) {
          controller!.value = valueStr;
          _changed = true;
        }
      }
    }
  }

  dynamic get flag {
    return _flag;
  }

  set flag(dynamic flag) {
    if (_flag != flag) {
      _flag = flag;
      notifyListeners();
    }
  }

  bool get changed {
    return _changed;
  }

  set changed(bool changed) {
    if (_changed != changed) {
      _changed = changed;
    }
  }

  clear() {
    if (controller != null) {
      if (controller is TextEditingController) {
        (controller as TextEditingController).clear();
      } else {
        controller!.value = null;
      }
    } else {
      if (dataField.inputType == InputType.label) {
      } else {
        if (_value != null) {
          _value = null;
          notifyListeners();
        }
      }
    }
  }

  @override
  dispose() {
    super.dispose();
    if (controller != null) {
      controller!.dispose();
    }
  }
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class DataFieldWidget extends StatefulWidget {
  final DataFieldController controller;
  final FocusNode? focusNode;

  const DataFieldWidget({
    super.key,
    required this.controller,
    this.focusNode,
  });

  @override
  State<StatefulWidget> createState() {
    return _DataFieldWidgetState();
  }
}

class _DataFieldWidgetState extends State<DataFieldWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  //获取初始化值，传入的初始值或者定义的初始值
  dynamic _getInitValue(BuildContext context) {
    dynamic v = widget.controller.value;

    return v;
  }

  Widget? _buildIcon() {
    Widget? icon = widget.controller.dataField.prefixIcon;
    if (icon == null) {
      final avatar = widget.controller.dataField.avatar;
      if (avatar != null) {
        icon = ImageUtil.buildImageWidget(imageContent: avatar);
      }
    }

    return icon;
  }

  Widget _buildLabel(BuildContext context) {
    ValueNotifier<dynamic>? controller = widget.controller.controller;
    if (controller == null) {
      controller = ValueNotifier<dynamic>(null);
      widget.controller.controller = controller;
      final value = widget.controller.value;
      controller.value = value;
    }
    String label = widget.controller.dataField.label;
    label = '${AppLocalizations.t(label)}:';
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 14.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildIcon() ?? nilBox,
          const SizedBox(
            width: 10.0,
          ),
          CommonAutoSizeText(label),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(
              child: ValueListenableBuilder(
            valueListenable: controller,
            builder: (BuildContext context, value, Widget? child) {
              value ??= '';
              return CommonAutoSizeText(value.toString(),
                  textAlign: TextAlign.start);
            },
          )),
        ]));
  }

  Widget _buildTextFormField(BuildContext context) {
    TextEditingController? controller =
        widget.controller.controller as TextEditingController?;
    controller ??= TextEditingController();
    final value = widget.controller.value;
    final valueStr = value == null ? '' : value.toString();
    controller.value = TextEditingValue(
        text: valueStr,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueStr.length, affinity: TextAffinity.downstream)));
    widget.controller.controller = controller;

    var dataFieldDef = widget.controller.dataField;
    var suffixIcon = dataFieldDef.suffixIcon;
    Widget? suffix;
    if (dataFieldDef.cancel) {
      suffix = IconButton(
          //如果文本长度不为空则显示清除按钮
          onPressed: () {
            controller!.clear();
          },
          icon: Icon(
            Icons.cancel,
            color: myself.primary,
          ));

      if (suffixIcon == null) {
        suffixIcon = suffix;
        suffix = null;
      }
    }
    String label = AppLocalizations.t(dataFieldDef.label);
    var textFormField = TextFormField(
      controller: controller,
      focusNode: widget.focusNode,
      keyboardType: dataFieldDef.textInputType,
      maxLines: dataFieldDef.maxLines,
      minLines: dataFieldDef.minLines,
      readOnly: dataFieldDef.readOnly,
      decoration: buildInputDecoration(
          suffix: suffix,
          hintText: dataFieldDef.hintText,
          labelText: label,
          prefixIcon: _buildIcon(),
          suffixIcon: suffixIcon),
      inputFormatters: dataFieldDef.inputFormatters,
      validator: dataFieldDef.validator,
      onChanged: dataFieldDef.onChanged,
      onEditingComplete: dataFieldDef.onEditingComplete,
      onFieldSubmitted: dataFieldDef.onFieldSubmitted,
    );

    return textFormField;
  }

  Widget _buildPasswordField(BuildContext context) {
    TextEditingController? controller =
        widget.controller.controller as TextEditingController?;
    controller ??= TextEditingController();
    final value = widget.controller.value;
    final valueStr = value == null ? '' : value.toString();
    controller.value = TextEditingValue(
        text: valueStr,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueStr.length, affinity: TextAffinity.downstream)));
    widget.controller.controller = controller;

    var dataFieldDef = widget.controller.dataField;
    Widget? suffix;
    if (dataFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller!.clear();
              },
              icon: Icon(
                Icons.cancel,
                color: myself.primary,
              ))
          : null;
    }

    bool pwdShow = widget.controller.flag ?? false;
    var textFormField = TextFormField(
      controller: controller,
      focusNode: widget.focusNode,
      keyboardType: dataFieldDef.textInputType,
      obscureText: !pwdShow,
      maxLines: 1,
      decoration: buildInputDecoration(
          suffix: suffix,
          hintText: dataFieldDef.hintText,
          labelText: AppLocalizations.t(dataFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon: IconButton(
            icon: Icon(
              pwdShow ? Icons.visibility_off : Icons.visibility,
              color: myself.primary,
            ),
            onPressed: () {
              setState(() {
                widget.controller.value = controller!.value.text;
                widget.controller.flag = !pwdShow;
              });
            },
          )),
      onChanged: dataFieldDef.onChanged,
      onEditingComplete: dataFieldDef.onEditingComplete,
      onFieldSubmitted: dataFieldDef.onFieldSubmitted,
    );
    return textFormField;
  }

  Widget _buildPinputField(BuildContext context) {
    TextEditingController? controller =
        widget.controller.controller as TextEditingController?;
    controller ??= TextEditingController();
    final value = widget.controller.value;
    final valueStr = value == null ? '' : value.toString();
    controller.value = TextEditingValue(
        text: valueStr,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueStr.length, affinity: TextAffinity.downstream)));
    widget.controller.controller = controller;

    var dataFieldDef = widget.controller.dataField;
    String label = AppLocalizations.t(dataFieldDef.label);
    var pinputField = Pinput(
      controller: controller,
      focusNode: widget.focusNode,
      keyboardType: dataFieldDef.textInputType!,
      readOnly: dataFieldDef.readOnly,
      inputFormatters: dataFieldDef.inputFormatters!,
      validator: dataFieldDef.validator,
      onChanged: dataFieldDef.onChanged,
      onSubmitted: dataFieldDef.onFieldSubmitted,
    );

    return pinputField;
  }

  ///多个字符串选择一个，对应的字段是字符串
  Widget _buildRadioField(BuildContext context) {
    widget.controller.controller = null;
    var dataFieldDef = widget.controller.dataField;
    var label = dataFieldDef.label;
    var options = dataFieldDef.options;
    List<Widget> children = [];
    var prefixIcon = _buildIcon();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    dynamic value = _getInitValue(context);
    if (options != null && options.isNotEmpty) {
      List<Widget> radioChildren = [];
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var radio = Radio<String>(
          onChanged: (String? value) {
            if (dataFieldDef.readOnly) {
              return;
            }
            widget.controller.value = value;
            var fn = dataFieldDef.onChanged;
            if (value != null && fn != null) {
              fn(value);
            }
            setState(() {});
          },
          value: option.value,
          groupValue: value,
        );
        var row = SizedBox(
            width: dataFieldDef.width ?? 120,
            child: Row(
              children: [
                radio,
                Expanded(
                    child: CommonAutoSizeText(AppLocalizations.t(option.label)))
              ],
            ));
        radioChildren.add(row);
      }
      children.add(Expanded(
          child: Wrap(
        children: radioChildren,
      )));
    }

    return Row(children: children);
  }

  ///多个字符串选择一个，对应的字段是字符串
  Widget _buildToggleField(BuildContext context) {
    widget.controller.controller = null;
    var dataFieldDef = widget.controller.dataField;
    var label = dataFieldDef.label;
    var options = dataFieldDef.options;
    List<String> labels = [];
    List<IconData?> icons = [];
    dynamic value = _getInitValue(context);
    int? index;
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        labels.add(AppLocalizations.t(option.label));
        icons.add(option.icon);
        if (value == option.value) {
          index = i;
        }
      }
    }

    var toggleSwitch = ToggleSwitch(
      initialLabelIndex: index,
      activeBgColor: [myself.primary],
      activeFgColor: Colors.white,
      inactiveBgColor: myself.secondary,
      inactiveFgColor: Colors.white,
      totalSwitches: labels.length,
      labels: labels,
      icons: icons,
      onToggle: (index) {
        if (dataFieldDef.readOnly) {
          return;
        }
        if (index != null) {
          widget.controller.value = options![index].value;
        } else {
          widget.controller.value = null;
        }
        var fn = dataFieldDef.onChanged;
        if (widget.controller.value != null && fn != null) {
          fn(widget.controller.value);
        }
      },
    );
    List<Widget> children = [];
    var prefixIcon = _buildIcon();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    children.addAll([
      const SizedBox(
        width: 15.0,
      ),
      toggleSwitch
    ]);
    return Row(children: children);
  }

  ///多个字符串选择多个，对应的字段是字符串的Set
  Widget _buildCheckboxField(BuildContext context) {
    widget.controller.controller = null;
    var dataFieldDef = widget.controller.dataField;
    var label = dataFieldDef.label;
    var options = dataFieldDef.options;

    List<Widget> children = [];
    var prefixIcon = _buildIcon();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    dynamic value = _getInitValue(context);
    value ??= <dynamic>{};
    Widget? checkWidget;
    if (options != null && options.isNotEmpty) {
      List<Widget> checkChildren = [];
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var checkbox = Checkbox(
          onChanged: (bool? selected) {
            if (dataFieldDef.readOnly) {
              return;
            }
            if (value != null) {
              if (selected == null || !selected) {
                value.remove(option.value);
              } else if (selected) {
                value.add(option.value);
              }
            }
            widget.controller.value = value;
            var fn = dataFieldDef.onChanged;
            if (widget.controller.value != null && fn != null) {
              fn(widget.controller.value);
            }
            setState(() {});
          },
          value: value.contains(option.value),
        );
        var row = SizedBox(
            width: dataFieldDef.width ?? 120,
            child: Row(
              children: [
                checkbox,
                Expanded(
                    child: CommonAutoSizeText(AppLocalizations.t(option.label)))
              ],
            ));
        checkChildren.add(row);
      }
      checkWidget = Wrap(
        children: checkChildren,
      );
    }
    if (checkWidget != null) {
      children.add(Expanded(child: checkWidget));
    }
    return Row(
      children: children,
    );
  }

  /// 多个字符串选择一个
  Widget _buildToggleButtonsField(BuildContext context) {
    widget.controller.controller = null;
    var dataFieldDef = widget.controller.dataField;
    var label = dataFieldDef.label;
    var options = dataFieldDef.options;
    List<Widget> toggleChildren = [];
    List<bool> isSelected = [];
    dynamic value = _getInitValue(context);
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        if (option.leading != null) {
          toggleChildren.add(option.leading!);
        } else {
          toggleChildren.add(Text(AppLocalizations.t(option.label)));
        }
        if (value == option.value) {
          isSelected.add(true);
        } else {
          isSelected.add(false);
        }
      }
    }
    var toggleButtons = ToggleButtons(
      borderRadius: borderRadius,
      fillColor: myself.primary,
      selectedColor: Colors.white,
      onPressed: (int newIndex) {
        if (dataFieldDef.readOnly) {
          return;
        }
        for (int i = 0; i < isSelected.length; ++i) {
          if (i == newIndex) {
            isSelected[i] = true;
          } else {
            isSelected[i] = false;
          }
        }
        Option option = options![newIndex];
        widget.controller.value = option.value;
        var fn = dataFieldDef.onChanged;
        if (widget.controller.value != null && fn != null) {
          fn(widget.controller.value);
        }
        setState(() {});
      },
      isSelected: isSelected,
      children: toggleChildren,
    );

    List<Widget> children = [];
    var prefixIcon = _buildIcon();
    if (prefixIcon != null) {
      children.add(const SizedBox(
        width: 10.0,
      ));
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    children.add(Text(AppLocalizations.t(label)));
    children.addAll([
      const SizedBox(
        width: 15,
      ),
      toggleButtons,
    ]);
    var row = Row(
      children: children,
    );

    return row;
  }

  ///适合数据类型为bool
  Widget _buildSwitchField(BuildContext context) {
    widget.controller.controller = null;
    var dataFieldDef = widget.controller.dataField;
    List<Widget> children = [];
    var prefixIcon = dataFieldDef.prefixIcon;
    if (prefixIcon != null) {
      children.add(prefixIcon);
      children.add(const SizedBox(
        width: 15.0,
      ));
    }
    var label = dataFieldDef.label;
    if (prefixIcon != null) {
      children.add(Text(AppLocalizations.t(label)));
      children.add(const SizedBox(
        width: 20.0,
      ));
    }
    var switcher = Transform.scale(
        scale: 0.8,
        child: Switch(
          activeColor: myself.primary,
          activeTrackColor: Colors.white,
          inactiveThumbColor: myself.secondary,
          inactiveTrackColor: Colors.grey,
          onChanged: (bool? value) {
            if (dataFieldDef.readOnly) {
              return;
            }
            widget.controller.value = value;
            var fn = dataFieldDef.onChanged;
            if (widget.controller.value != null && fn != null) {
              fn(widget.controller.value);
            }
            setState(() {});
          },
          value: widget.controller.value ?? false,
        ));
    children.add(switcher);

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
        child: Row(children: children));
  }

  Widget _buildDropdownButton(BuildContext context) {
    widget.controller.controller = null;
    var dataFieldDef = widget.controller.dataField;
    var options = dataFieldDef.options;
    List<DropdownMenuItem<String>> children = [];
    if (options != null && options.isNotEmpty) {
      for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        var item = DropdownMenuItem<String>(
          value: option.value,
          child: Text(
            AppLocalizations.t(option.label),
            style: const TextStyle(color: Colors.black),
          ),
        );
        children.add(item);
      }
    }
    var dropdownButton = Row(children: [
      Text(AppLocalizations.t(dataFieldDef.label)),
      const SizedBox(
        width: 15.0,
      ),
      DropdownButton<String>(
        dropdownColor: myself.primary,
        padding: const EdgeInsets.all(10.0),
        hint: Text(AppLocalizations.t(dataFieldDef.hintText ?? '')),
        isDense: true,
        // elevation: 0,
        value: widget.controller.value,
        items: children,
        onChanged: (String? value) {
          widget.controller.value = value;
          var fn = dataFieldDef.onChanged;
          if (widget.controller.value != null && fn != null) {
            fn(widget.controller.value);
          }
          setState(() {});
        },
      )
    ]);

    return dropdownButton;
  }

  Widget _buildInputDate(BuildContext context) {
    String? initialValue = widget.controller.value;
    var valueText = '';
    if (initialValue != null) {
      valueText = DateUtil.toLocal(initialValue);
    }
    var controller = TextEditingController();
    widget.controller.controller = controller;
    controller.value = TextEditingValue(
        text: valueText,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueText.length, affinity: TextAffinity.downstream)));

    var dataFieldDef = widget.controller.dataField;
    Widget? suffix;
    if (dataFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.cancel, color: Colors.grey))
          : null;
    }
    var textFormField = TextFormField(
      controller: controller,
      focusNode: widget.focusNode,
      keyboardType: dataFieldDef.textInputType,
      readOnly: true,
      decoration: buildInputDecoration(
        labelText: AppLocalizations.t(dataFieldDef.label),
        prefixIcon: _buildIcon(),
        suffixIcon: IconButton(
            icon: Icon(Icons.date_range, color: myself.primary),
            onPressed: () async {
              DateTime? initialDate;
              if (initialValue != null) {
                initialDate = DateUtil.toDateTime(initialValue);
              }
              var value =
                  await _showDatePicker(context, initialDate: initialDate);
              widget.controller.value = value;
            }),
        suffix: suffix,
        hintText: dataFieldDef.hintText,
      ),
    );

    return textFormField;
  }

  Future<DateTime?> _showDatePicker(BuildContext context,
      {DateTime? initialDate}) {
    initialDate = initialDate ?? DateTime.now();
    return showDatePicker(
      context: context,
      // 初始化选中日期
      initialDate: initialDate,
      // 开始日期
      firstDate: initialDate.subtract(const Duration(days: 365)),
      // 结束日期
      lastDate: initialDate.add(const Duration(days: 365)),
      // 当前日期
      //currentDate: initialDate,
      // 日历弹框样式
      initialEntryMode: DatePickerEntryMode.calendar,
      // 文字方向
      textDirection: TextDirection.ltr,
      // 左上方提示
      helpText: AppLocalizations.t("Current date"),
      // 取消按钮文案
      cancelText: AppLocalizations.t("Cancel"),
      // 确认按钮文案
      confirmText: AppLocalizations.t("Confirm"),
      // 格式错误提示
      errorFormatText: AppLocalizations.t("Date format error"),
      // 输入不在 first 与 last 之间日期提示
      errorInvalidText: AppLocalizations.t("Date range invalid error"),
      // 输入框上方提示
      fieldLabelText: AppLocalizations.t("Date"),
      // 输入框为空时内部提示
      fieldHintText: AppLocalizations.t("Must be not empty"),
      // 日期选择模式，默认为天数选择
      initialDatePickerMode: DatePickerMode.day,
      // 是否为根导航器
      useRootNavigator: true,
      // 设置不可选日期，这里将 2020-10-15，2020-10-16，2020-10-17 三天设置不可选
      // selectableDayPredicate: (dayTime) {
      //   if (dayTime == DateTime(2020, 10, 15) ||
      //       dayTime == DateTime(2020, 10, 16) ||
      //       dayTime == DateTime(2020, 10, 17)) {
      //     return false;
      //   }
      //   return true;
      // }
    );
  }

  Widget _buildInputTime(BuildContext context) {
    String? initialValue = widget.controller.value;
    var valueText = '';
    if (initialValue != null) {
      valueText = initialValue;
    }
    var controller = TextEditingController();
    widget.controller.controller = controller;
    controller.value = TextEditingValue(
        text: valueText,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueText.length, affinity: TextAffinity.downstream)));

    var dataFieldDef = widget.controller.dataField;
    Widget? suffix;
    if (dataFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.cancel, color: Colors.grey))
          : null;
    }
    var textFormField = TextFormField(
        controller: controller,
        focusNode: widget.focusNode,
        keyboardType: dataFieldDef.textInputType,
        readOnly: true,
        decoration: buildInputDecoration(
          labelText: AppLocalizations.t(dataFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon: IconButton(
              icon: Icon(Icons.access_time_filled, color: myself.primary),
              onPressed: () async {
                TimeOfDay? initialTime;
                if (initialValue != null) {
                  initialTime = DateUtil.toTime(initialValue);
                }
                var value =
                    await _showTimePicker(context, initialTime: initialTime);
                widget.controller.value = value;
              }),
          suffix: suffix,
          hintText: dataFieldDef.hintText,
        ));

    return textFormField;
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context,
      {TimeOfDay? initialTime}) {
    var now = DateTime.now();
    initialTime = initialTime ?? TimeOfDay(hour: now.hour, minute: now.minute);
    return showTimePicker(
      context: context,
      // 初始化选中日期
      initialTime: initialTime,
      // 日历弹框样式
      initialEntryMode: TimePickerEntryMode.dial,
      // 取消按钮文案
      cancelText: AppLocalizations.t("Cancel"),
      // 确认按钮文案
      confirmText: AppLocalizations.t("Confirm"),
      hourLabelText: AppLocalizations.t("Hour"),
      minuteLabelText: AppLocalizations.t("Minute"),
      // 输入不在 first 与 last 之间日期提示
      errorInvalidText: AppLocalizations.t("Invalid error"),
      useRootNavigator: true,
    );
  }

  Widget _buildInputDateTime(BuildContext context) {
    String? initialValue = widget.controller.value;
    var valueText = '';
    if (initialValue != null) {
      valueText = DateUtil.toLocal(initialValue);
    }
    var controller = TextEditingController();
    widget.controller.controller = controller;
    controller.value = TextEditingValue(
        text: valueText,
        selection: TextSelection.fromPosition(TextPosition(
            offset: valueText.length, affinity: TextAffinity.downstream)));
    var dataFieldDef = widget.controller.dataField;
    Widget? suffix;
    if (dataFieldDef.cancel) {
      suffix = controller.text.isNotEmpty
          ? IconButton(
              //如果文本长度不为空则显示清除按钮
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.cancel, color: Colors.grey))
          : null;
    }
    var textFormField = TextFormField(
        controller: controller,
        focusNode: widget.focusNode,
        keyboardType: dataFieldDef.textInputType,
        readOnly: true,
        decoration: buildInputDecoration(
          labelText: AppLocalizations.t(dataFieldDef.label),
          prefixIcon: _buildIcon(),
          suffixIcon: IconButton(
              icon: Icon(Icons.date_range, color: myself.primary),
              onPressed: () async {
                DateTime? initialDate;
                if (initialValue != null) {
                  initialDate = DateUtil.toDateTime(initialValue);
                }
                var value = await _showDateTimePicker(context,
                    initialDate: initialDate);
                widget.controller.value = value;
              }),
          suffix: suffix,
          hintText: dataFieldDef.hintText,
        ));

    return textFormField;
  }

  Future<DateTime?> _showDateTimePicker(BuildContext context,
      {DateTime? initialDate}) {
    initialDate = initialDate ?? DateTime.now();
    return showOmniDateTimePicker(
      context: context,
      initialDate: initialDate,
      // 开始日期
      firstDate: initialDate.subtract(const Duration(days: 365)),
      // 结束日期
      lastDate: initialDate.add(const Duration(days: 365)),
      is24HourMode: true,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      selectableDayPredicate: (dateTime) {
        // Disable 25th Feb 2023
        if (dateTime == DateTime(2023, 2, 25)) {
          return false;
        } else {
          return true;
        }
      },
    );
  }

  _showDateTimeRangePicker(BuildContext context,
      {DateTime? startInitialDate, DateTime? endInitialDate}) {
    startInitialDate = startInitialDate ?? DateTime.now();
    endInitialDate = endInitialDate ?? DateTime.now();
    return showOmniDateTimeRangePicker(
      context: context,
      startInitialDate: startInitialDate,
      startFirstDate: startInitialDate.subtract(const Duration(days: 365)),
      startLastDate: startInitialDate.add(const Duration(days: 365)),
      endInitialDate: endInitialDate,
      endFirstDate: endInitialDate.subtract(const Duration(days: 365)),
      endLastDate: endInitialDate.add(const Duration(days: 365)),
      is24HourMode: true,
      isShowSeconds: false,
      minutesInterval: 1,
      secondsInterval: 1,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      // selectableDayPredicate: (dateTime) {
      //   // Disable 25th Feb 2023
      //   if (dateTime == DateTime(2023, 2, 25)) {
      //     return false;
      //   } else {
      //     return true;
      //   }
      // },
    );
  }

  CalendarDatePicker _calendarDatePicker(DatePickerMode mode) {
    return CalendarDatePicker(
        initialDate: DateTime.now(),
        // 初始化选中日期
        currentDate: DateTime(2020, 10, 18),
        firstDate: DateTime(2020, 9, 10),
        // 开始日期
        lastDate: DateTime(2022, 9, 10),
        // 结束日期
        initialCalendarMode: mode,
        // 日期选择样式
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

  Widget _buildColorPicker(BuildContext context) {
    widget.controller.controller = null;
    var dataFieldDef = widget.controller.dataField;
    var label = dataFieldDef.label;
    dynamic value = _getInitValue(context);
    if (value != null && value is int) {
      value = Color(value);
    }
    Widget colorPicker = ColorPicker(
      label: label,
      onColorChanged: (Color color) {
        widget.controller.value = color.value;
      },
      initColor: value ?? myself.primary,
    );

    return colorPicker;
  }

  @override
  Widget build(BuildContext context) {
    Widget dataFieldWidget;
    var customWidget = widget.controller.dataField.customWidget;
    if (customWidget != null) {
      dataFieldWidget = customWidget;
      return dataFieldWidget;
    }
    var inputType = widget.controller.dataField.inputType;
    switch (inputType) {
      case InputType.label:
        dataFieldWidget = _buildLabel(context);
        break;
      case InputType.text:
        dataFieldWidget = _buildTextFormField(context);
        break;
      case InputType.textarea:
        dataFieldWidget = _buildTextFormField(context);
        break;
      case InputType.password:
        dataFieldWidget = _buildPasswordField(context);
        break;
      case InputType.pinput:
        dataFieldWidget = _buildPinputField(context);
        break;
      case InputType.toggleButtons:
        dataFieldWidget = _buildToggleButtonsField(context);
        break;
      case InputType.checkbox:
        dataFieldWidget = _buildCheckboxField(context);
        break;
      case InputType.radio:
        dataFieldWidget = _buildRadioField(context);
        break;
      case InputType.select:
        dataFieldWidget = _buildDropdownButton(context);
        break;
      case InputType.toggle:
        dataFieldWidget = _buildToggleField(context);
        break;
      case InputType.switcher:
        dataFieldWidget = _buildSwitchField(context);
        break;
      case InputType.date:
        dataFieldWidget = _buildInputDate(context);
        break;
      case InputType.time:
        dataFieldWidget = _buildInputTime(context);
        break;
      case InputType.datetime:
        dataFieldWidget = _buildInputDateTime(context);
        break;
      case InputType.color:
        dataFieldWidget = _buildColorPicker(context);
        break;
      default:
        dataFieldWidget = _buildTextFormField(context);
    }
    return dataFieldWidget;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
