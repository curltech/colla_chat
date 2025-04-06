import 'package:flutter/material.dart';

class Option<T> {
  String label;
  T value;
  String? hint;
  bool selected;
  Widget? leading;
  IconData? icon;

  Option(this.label, this.value,
      {this.selected = false, this.leading, this.icon, this.hint});

  Option<T> copy() {
    Option<T> option =
        Option<T>(label, value, selected: selected, leading: leading, hint: hint);

    return option;
  }
}
