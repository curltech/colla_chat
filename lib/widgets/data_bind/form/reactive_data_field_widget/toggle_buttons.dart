import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ReactiveToggleButtons<T> extends ReactiveFormField<T, T> {
  ReactiveToggleButtons({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    required List<Option<T>> options,
    MouseCursor? mouseCursor,
    MaterialTapTargetSize? tapTargetSize,
    TextStyle? textStyle,
    BoxConstraints? constraints,
    Color? color,
    Color? selectedColor,
    Color? disabledColor,
    Color? fillColor,
    Color? focusColor,
    Color? highlightColor,
    Color? hoverColor,
    Color? splashColor,
    List<FocusNode>? focusNodes,
    bool renderBorder = true,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? disabledBorderColor,
    BorderRadius? borderRadius,
    double? borderWidth,
    ReactiveFormFieldCallback<T>? onToggle,
    Axis direction = Axis.horizontal,
    VerticalDirection verticalDirection = VerticalDirection.down,
  }) : super(
          builder: (field) {
            T? value = field.value;
            List<bool> isSelected = [];
            List<Widget> children = [];
            for (var i = 0; i < options.length; ++i) {
              var option = options[i];
              if (value == option.value) {
                isSelected.add(true);
              } else {
                isSelected.add(false);
              }
              if (option.icon != null) {
                children.add(Icon(option.icon!));
              } else {
                children.add(Text(option.label));
              }
            }
            return ToggleButtons(
              isSelected: isSelected,
              onPressed: (int index) {
                var option = options[index];
                field.didChange.call(option.value);
                onToggle?.call(field.control);
              },
              mouseCursor: mouseCursor,
              tapTargetSize: tapTargetSize,
              textStyle: textStyle,
              constraints: constraints,
              color: color,
              selectedColor: selectedColor,
              disabledColor: disabledColor,
              fillColor: fillColor,
              focusColor: focusColor,
              highlightColor: highlightColor,
              hoverColor: hoverColor,
              splashColor: splashColor,
              focusNodes: focusNodes,
              renderBorder: renderBorder,
              borderColor: borderColor,
              selectedBorderColor: selectedBorderColor,
              disabledBorderColor: disabledBorderColor,
              borderRadius: borderRadius,
              borderWidth: borderWidth,
              direction: direction,
              verticalDirection: verticalDirection,
              children: children,
            );
          },
        );
}
