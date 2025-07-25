import 'package:colla_chat/l10n/localization.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_fluent_ui/reactive_fluent_ui.dart' as fui;

class ReactiveFluentCheckboxGroup<T> extends ReactiveFormField<T, Set<T>> {
  ReactiveFluentCheckboxGroup({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    ReactiveFormFieldCallback<T>? onChanged,
    double width = 120,
    bool tristate = false,
    MouseCursor? mouseCursor,
    Color? activeColor,
    WidgetStateProperty<Color?>? fillColor,
    Color? checkColor,
    Color? focusColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? overlayColor,
    double? splashRadius,
    MaterialTapTargetSize? materialTapTargetSize,
    VisualDensity? visualDensity,
    FocusNode? focusNode,
    bool autofocus = false,
    OutlinedBorder? shape,
    BorderSide? side,
    bool isError = false,
    String? semanticLabel,
    Widget? prefixIcon,
    String? label,
  }) : super(builder: (field) {
          Set<T>? value = field.value;
          List<Widget> checkChildren = [];
          if (options.isNotEmpty) {
            value ??= {};
            for (var i = 0; i < options.length; ++i) {
              var option = options[i];
              var checkbox = fui.ReactiveFluentCheckBox<bool>(
                focusNode: focusNode,
                autofocus: autofocus,
                semanticLabel: semanticLabel,
              );
              var row = SizedBox(
                  width: width,
                  child: Row(
                    children: [
                      checkbox,
                      Expanded(
                          child: AutoSizeText(AppLocalizations.t(option.label)))
                    ],
                  ));
              checkChildren.add(row);
            }
          }
          return Wrap(
            children: checkChildren,
          );
        });
}
