import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/button_widget.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_data_field.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_language_picker/reactive_language_picker.dart';

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
        case DataType.dateTimeRange:
          formControl = FormControl<DateTimeRange>(
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
      formControl.valueChanges.listen((dynamic value) {
        onData(name, value);
      }, onError: onError, onDone: onDone);
      formControl.touchChanges.listen((bool touch) {
        onTouch(name, touch);
      }, onError: onError, onDone: onDone);
    }
    formGroup = FormGroup(formControls);
    keyboardActionsConfig = KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: myself.primary,
      nextFocus: false,
      actions: actions,
    );
  }

  onData(String name, dynamic value) {}

  onTouch(String name, bool touch) {}

  onError(Object value, StackTrace stackTrace) {}

  onDone() {}

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
  dynamic parse(String name, dynamic value, {bool vm = true}) {
    if (value == null) {
      return null;
    }
    PlatformDataField? platformDataField = dataFieldMap[name];
    if (platformDataField == null) {
      return value;
    }
    PlatformControlValueAccessor accessor =
        PlatformControlValueAccessor(platformDataField);
    if (vm) {
      return accessor.viewToModelValue(value);
    } else {
      return accessor.modelToViewValue(value);
    }
  }

  Map<String, Object?> get values {
    return formGroup.value.map((key, value) {
      return MapEntry(key, parse(key, value));
    });
  }

  set values(Map<String, Object?>? values) {
    formGroup.value = values?.map((key, value) {
      return MapEntry(key, parse(key, value, vm: false));
    });
  }

  dynamic getValue(String name) {
    dynamic value = formGroup.control(name).value;

    return parse(name, value);
  }

  setValue(String name, dynamic value) {
    formGroup.control(name).value = parse(name, value, vm: false);
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

  markAsEnabled(String name) {
    return formGroup.control(name).markAsEnabled();
  }

  markAsDisabled(String name) {
    return formGroup.control(name).markAsDisabled();
  }

  markAsTouched(String name) {
    return formGroup.control(name).markAsTouched();
  }

  markAsUntouched(String name) {
    return formGroup.control(name).markAsUntouched();
  }

  markAsDirty(String name) {
    return formGroup.control(name).markAsDirty();
  }

  markAsPending(String name) {
    return formGroup.control(name).markAsPending();
  }

  markAsPristine(String name) {
    return formGroup.control(name).markAsPristine();
  }

  bool get valid {
    return formGroup.valid;
  }

  dispose() {
    formGroup.dispose();
  }
}

/// 模型值一般是简单数据类型，比如String，int，double，bool
/// 视图值一般是复杂数据类型，比如Language，Color，DataTime
class PlatformControlValueAccessor<M, V> extends ControlValueAccessor<M, V> {
  final PlatformDataField platformDataField;

  PlatformControlValueAccessor(this.platformDataField);

  /// 数据转换，vm为true，表示视图值转换成模型值
  /// 否则，表示模型值转换成视图值
  dynamic _parse(dynamic value, {bool vm = true}) {
    if (value == null) {
      return null;
    }

    DataType dataType = platformDataField.dataType;
    DataType? outputDataType = platformDataField.outputDataType;
    if (outputDataType == null || outputDataType == dataType) {
      return value;
    }
    if (vm) {
      dataType = outputDataType;
    }
    switch (dataType) {
      /// 其他类型转换成字符串，DateTime，Language需要特别处理
      case DataType.string:
        if (value is! String) {
          if (value is DateTime) {
            return value.toLocal().toIso8601String();
          } else if (value is Language) {
            return value.isoCode;
          } else {
            return value.toString();
          }
        }
        break;
      case DataType.double:
        if (value is! double) {
          return double.parse(value.toString());
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
          return JsonUtil.toJson(value);
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
      case DataType.dateTimeRange:
        if (value is! DateTimeRange && value is Set) {
          return DateTimeRange<DateTime>(start: value.first, end: value.last);
        }
        if (value is! Set && value is DateTimeRange) {
          return {value.start, value.end};
        }
        break;
      case DataType.language:
        if (value is! Color && value is String) {
          return Language.fromIsoCode(value);
        }
    }

    return value;
  }

  @override
  V? modelToViewValue(M? modelValue) {
    if (modelValue == null) return null;
    return _parse(modelValue);
  }

  @override
  M? viewToModelValue(V? viewValue) {
    return _parse(viewValue, vm: true);
  }
}

class PlatformReactiveForm extends StatelessWidget {
  final Function(Map<String, dynamic> values)? onSubmit;
  final Function(Map<String, dynamic> values)? onReset;
  final List<FormButton>? formButtons;
  final bool showResetButton;
  final String submitLabel;
  final double? height; //高度
  final double? width; //宽度
  final EdgeInsetsGeometry padding;
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
    this.padding = const EdgeInsets.all(10.0),
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
      btns.add(ReactiveFormConsumer(
        builder: (context, formGroup, child) {
          return TextButton(
            style: platformReactiveFormController.valid ? mainStyle : style,
            onPressed: platformReactiveFormController.valid
                ? () {
                    if (onSubmit != null) {
                      var values = platformReactiveFormController.values;
                      onSubmit?.call(values);
                    }
                  }
                : null,
            child: AutoSizeText(AppLocalizations.t(submitLabel)),
          );
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
    List<Widget> children = [
      SizedBox(
        height: spacing,
      )
    ];
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

    Widget widgets = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: children,
    );

    final KeyboardActions keyboardActions = KeyboardActions(
        config: platformReactiveFormController.keyboardActionsConfig,
        child: SingleChildScrollView(child: widgets));

    return [
      Expanded(child: keyboardActions),
      SizedBox(
        height: buttonSpacing,
      ),
      _buildButtonBar(),
      SizedBox(
        height: buttonSpacing,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ReactiveForm reactiveForm = ReactiveForm(
      formGroup: platformReactiveFormController.formGroup,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: _buildFormFieldWidget(),
      ),
    );

    return Container(
        padding: padding, height: height, width: width, child: reactiveForm);
  }
}
