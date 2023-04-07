import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

///消息体：撤销消息
class CancelMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const CancelMessage({Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget leading = Icon(
      Icons.cancel,
      color: myself.primary,
    );
    Widget tile = Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          leading,
          const SizedBox(
            width: 5,
          ),
          Expanded(child: CommonAutoSizeText(content)),
        ]),
      ),
    );
    return Card(elevation: 0, child: tile);
  }
}
