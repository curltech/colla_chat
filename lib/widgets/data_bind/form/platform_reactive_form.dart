import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/button_widget.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_data_field.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:colla_chat/plugin/talker_logger.dart';

class PlatformReactiveFormController {
  final List<PlatformDataField> dataFields;
  final Map<String, PlatformDataField> dataFieldMap = {};
  late final FormGroup formGroup;
  final Map<String, FocusNode> focusNodes = {};
  late final KeyboardActionsConfig keyboardActionsConfig;

  PlatformReactiveFormController(this.dataFields) {
    _init();
  }

  _init() {
    Map<String, FormControl> formControls = {};
    final List<KeyboardActionsItem> actions = [];
    for (var i = 0; i < dataFields.length; i++) {
      PlatformDataField platformDataField = dataFields[i];
      var name = platformDataField.name;
      dataFieldMap[name] = platformDataField;
      var initValue = platformDataField.initValue;
      var validators = platformDataField.validators ?? const [];
      FormControl formControl;
      var dataType = platformDataField.dataType;
      switch (dataType) {
        case DataType.int:
          formControl = FormControl<int>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.num:
          formControl = FormControl<num>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.bool:
          formControl = FormControl<bool>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.double:
          formControl = FormControl<double>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.datetime:
          formControl = FormControl<DateTime>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.date:
          formControl = FormControl<DateTime>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.time:
          formControl = FormControl<TimeOfDay>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.list:
          formControl = FormControl<List>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.map:
          formControl = FormControl<Map>(
            value: initValue,
            validators: validators,
          );
          break;
        case DataType.set:
          formControl = FormControl<Set>(
            value: initValue,
            validators: validators,
          );
          break;
        default:
          formControl = FormControl<String>(
            value: initValue,
            validators: validators,
          );
          break;
      }

      var inputType = platformDataField.inputType;
      if (inputType == InputType.text ||
          inputType == InputType.password ||
          inputType == InputType.textarea) {
        var focusNode = FocusNode();
        focusNodes[name] = focusNode;
        KeyboardActionsItem action = KeyboardActionsItem(
          focusNode: focusNode,
          displayActionBar: false,
          displayArrows: false,
          displayDoneButton: false,
        );
        actions.add(action);
      }

      formControls[name] = formControl;
    }
    formGroup = FormGroup(formControls);
    keyboardActionsConfig = KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: myself.primary,
      nextFocus: false,
      actions: actions,
    );
  }

  Map<String, Object?> get rawValues {
    return formGroup.value;
  }

  set rawValues(Map<String, Object?>? values) {
    formGroup.value = values;
  }

  dynamic getRawValue(String name) {
    return formGroup.control(name).value;
  }

  setRawValue(String name, dynamic value) {
    formGroup.control(name).value = value;
  }

  ///获取真实值，如果控制器为空，返回_value，否则取控制器的值，并覆盖_value
  dynamic parse(String name, dynamic value, {bool get = true}) {
    if (value == null) {
      return null;
    }
    PlatformDataField? platformDataField = dataFieldMap[name];
    if (platformDataField == null) {
      return value;
    }
    DataType dataType = platformDataField.dataType;
    DataType? outputDataType = platformDataField.outputDataType;
    if (outputDataType == null || outputDataType == dataType) {
      return value;
    }
    if (get) {
      dataType = outputDataType;
    }
    switch (dataType) {
      case DataType.string:
        if (value is! String) {
          if (value is DateTime) {
            return value.toLocal().toIso8601String();
          } else {
            return value.toString();
          }
        }
        break;
      case DataType.double:
        if (value is! double) {
          return num.parse(value.toString());
        }
        break;
      case DataType.int:
        if (value is! int) {
          if (value is Color) {
            return value.toARGB32();
          }
          return int.parse(value.toString());
        }
        break;
      case DataType.num:
        if (value is! num) {
          return num.parse(value.toString());
        }
        break;
      case DataType.bool:
        if (value is! bool) {
          return bool.parse(value.toString());
        }
        break;
      case DataType.datetime:
        if (value is! DateTime) {
          return DateUtil.toDateTime(value.toString());
        }
        break;
      case DataType.date:
        if (value is! DateTime) {
          return DateUtil.toDateTime(value.toString());
        }
        break;
      case DataType.time:
        if (value is! TimeOfDay) {
          return DateUtil.toTime(value.toString());
        }
        break;
      case DataType.list:
        if (value is! List) {
          return [value];
        }
        break;
      case DataType.map:
        if (value is! Map) {
          return {name: value};
        }
        break;
      case DataType.set:
        if (value is! Set) {
          return {value};
        }
        break;
      case DataType.percentage:
        if (value is num) {
          return (value * 100).toString();
        }
        break;
      case DataType.color:
        if (value is! Color && value is int) {
          return Color(value);
        }
    }

    return value;
  }

  Map<String, Object?> get values {
    return formGroup.value.map((key, value) {
      return MapEntry(key, parse(key, value));
    });
  }

  set values(Map<String, Object?>? values) {
    formGroup.value = values?.map((key, value) {
      return MapEntry(key, parse(key, value, get: false));
    });
  }

  dynamic getValue(String name) {
    dynamic value = formGroup.control(name).value;

    return parse(name, value);
  }

  setValue(String name, dynamic value) {
    formGroup.control(name).value = parse(name, value, get: false);
  }

  reset({Map<String, Object?>? values}) {
    return formGroup.reset(value: values);
  }

  focus(String name) {
    return formGroup.control(name).focus();
  }

  unfocus(String name) {
    return formGroup.control(name).unfocus();
  }

  markAsDisabled(String name) {
    return formGroup.control(name).markAsDisabled();
  }

  markAsTouched(String name) {
    return formGroup.control(name).markAsTouched();
  }
}

class PlatformReactiveForm extends StatelessWidget {
  final Function(Map<String, dynamic> values)? onSubmit;
  final Function(Map<String, dynamic> values)? onReset;
  final List<FormButton>? formButtons;
  final bool showResetButton;
  final String submitLabel;
  final double? height; //高度
  final double? width; //高度
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;
  final double buttonSpacing;
  final List<Widget>? heads;
  final List<Widget>? tails;
  final PlatformReactiveFormController platformReactiveFormController;

  const PlatformReactiveForm({
    super.key,
    required this.platformReactiveFormController,
    this.onSubmit,
    this.onReset,
    this.formButtons,
    this.showResetButton = true,
    this.submitLabel = 'Submit',
    this.height,
    this.width,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.spacing = 0.0,
    this.buttonSpacing = 10.0,
    this.heads,
    this.tails,
  });

  Widget _buildButtonBar() {
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    List<Widget> btns = [];
    if (showResetButton) {
      btns.add(TextButton(
        style: style,
        child: AutoSizeText(AppLocalizations.t('Reset')),
        onPressed: () {
          platformReactiveFormController.reset();
          var values = platformReactiveFormController.values;
          onReset?.call(values);
        },
      ));
    }
    if (formButtons == null && onSubmit != null) {
      btns.add(TextButton(
        style: mainStyle,
        child: AutoSizeText(AppLocalizations.t(submitLabel)),
        onPressed: () {
          if (onSubmit != null) {
            var values = platformReactiveFormController.values;
            onSubmit?.call(values);
          }
        },
      ));
    } else {
      for (FormButton formButton in formButtons!) {
        btns.add(TextButton(
          style: formButton.buttonStyle,
          child: AutoSizeText(AppLocalizations.t(formButton.label)),
          onPressed: () {
            if (formButton.onTap != null) {
              var values = platformReactiveFormController.values;
              formButton.onTap?.call(values);
            }
          },
        ));
      }
    }

    return OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: buttonSpacing,
      overflowSpacing: buttonSpacing,
      children: btns,
    );
  }

  List<Widget> _buildFormFieldWidget() {
    List<Widget> children = [];
    if (heads != null) {
      children.addAll(heads!);
      children.add(SizedBox(
        height: spacing,
      ));
    }

    for (var i = 0; i < platformReactiveFormController.dataFields.length; i++) {
      PlatformDataField platformDataField =
          platformReactiveFormController.dataFields[i];
      var name = platformDataField.name;
      FocusNode? focusNode = platformReactiveFormController.focusNodes[name];
      children.add(PlatformReactiveDataField(
        platformDataField: platformDataField,
        formGroup: platformReactiveFormController.formGroup,
        focusNode: focusNode,
      ));
      children.add(SizedBox(
        height: spacing,
      ));
    }

    if (tails != null) {
      children.add(SizedBox(
        height: spacing,
      ));
      children.addAll(tails!);
    }

    children.add(SizedBox(
      height: buttonSpacing,
    ));
    children.add(_buildButtonBar());
    children.add(SizedBox(
      height: buttonSpacing,
    ));

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final ReactiveForm reactiveForm = ReactiveForm(
      formGroup: platformReactiveFormController.formGroup,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildFormFieldWidget(),
      ),
    );
    final KeyboardActions formWidget = KeyboardActions(
        config: platformReactiveFormController.keyboardActionsConfig,
        child: SingleChildScrollView(child: reactiveForm));

    return SizedBox(height: height, width: width, child: formWidget);
  }
}
