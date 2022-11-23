import 'package:flutter/material.dart';

class Option<T> {
  String label;
  T value;
  String? hint;
  bool checked;
  Widget? leading;

  Option(this.label, this.value,
      {this.checked = false, this.leading, this.hint});
}
