import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pip/flutter_pip.dart';

/// 用于ios的画中画功能
class IosPipController {
  Future<bool?> setDisplayText(
    String name,
    String content,
    List<Map<dynamic, dynamic>> chatList,
  ) async {
    return await InnerPipUtil.setDisplayText(name, content, chatList);
  }

  Future<bool?> displayThePipWindow() async {
    return await InnerPipUtil.displayThePipWindow();
  }

  Future<bool?> displayOrHide() async {
    return await InnerPipUtil.displayOrHide();
  }

  Future<bool?> get alreadyDisplayedPip async {
    return await InnerPipUtil.alreadyDisplayedPip;
  }
}

class IosPipWidget extends StatelessWidget {
  final IosPipController iosPipController;

  const IosPipWidget({super.key, required this.iosPipController});

  @override
  Widget build(BuildContext context) {
    FlutterPip();
    return InnerPipUtil.pipNativeWidget();
  }
}
