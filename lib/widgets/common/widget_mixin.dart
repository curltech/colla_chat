import 'package:flutter/material.dart';

mixin BackButtonMixin on Widget {
  bool get withBack;
}

mixin RouteNameMixin on Widget {
  String get routeName;
}
