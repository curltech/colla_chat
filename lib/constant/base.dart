import 'package:flutter/widgets.dart';

class Option {
  String label;
  String value;
  String? hint;

  Option(this.label, this.value, {this.hint});
}

const int defaultLimit = 10;
const int defaultOffset = 0;

//xs (extra small),
const xsSize = Size(16, 16);
//sm (small),
const smSize = Size(24, 24);
//md (medium),
const mdSize = Size(32, 32);
//lg (large),
const lgSize = Size(48, 48);
//xl (extra large)
const xlSize = Size(64, 64);

const defaultIcon = 'assets/icons/favicon-96x96.png';
final defaultImage = Image.asset(
  defaultIcon,
  width: 48,
  height: 48,
  fit: BoxFit.fill,
);
const defaultAvatar = 'assets/images/colla-o1.png';
const defaultGroupAvatar = 'assets/images/colla-o1.png';
