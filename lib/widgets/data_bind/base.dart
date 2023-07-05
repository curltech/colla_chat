import 'package:flutter/material.dart';

class Option<T> {
  String label;
  T value;
  String hint;
  bool checked;
  Widget? leading;
  IconData? icon;

  Option(this.label, this.value,
      {this.checked = false, this.leading, this.icon, required this.hint});

  Option<T> copy() {
    Option<T> option =
        Option<T>(label, value, checked: checked, leading: leading, hint: hint);

    return option;
  }
}
