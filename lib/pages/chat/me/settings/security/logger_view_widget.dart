import 'dart:io';

import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

///日志显示组件
class LoggerViewWidget extends StatelessWidget {
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  LoggerViewWidget({
    Key? key,
  }) : super(key: key);

  Future<String> _buildContent(BuildContext context) async {
    var current = DateTime.now();
    var filename =
        'colla_chat-${current.year}-${current.month}-${current.day}.log';
    filename = p.join(myself.myPath, filename);
    var file = File(filename);
    bool exist = await file.exists();
    if (exist) {
      return file.readAsStringSync();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(5),
        child: ExtendedText(
          key: UniqueKey(),
          '',
          style: const TextStyle(
              //fontSize: 16.0,
              ),
          specialTextSpanBuilder: customSpecialTextSpanBuilder,
        ));
  }
}
