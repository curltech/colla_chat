import 'package:flutter/widgets.dart';

class Option {
  String label;
  String value;
  String? hint;

  Option(this.label, this.value, {this.hint});
}

const defaultIcon = 'assets/icons/favicon-96x96.png';
final defaultImage = Image.asset(
  defaultIcon,
  width: 32,
  height: 32,
  fit: BoxFit.fill,
);
const defaultAvatar = 'assets/images/colla-o1.png';
const defaultGroupAvatar = 'assets/images/colla-o1.png';
