import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';

///消息体：文件消息
class FileMessage extends StatelessWidget {
  final String title;
  final String mimeType;
  final String messageId;
  final bool isMyself;

  const FileMessage(
      {Key? key,
      required this.messageId,
      required this.isMyself,
      required this.title,
      required this.mimeType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var tile = ListTile(
      leading: Mimecon(
        mimetype: mimeType,
        color: myself.primary,
        size: 36,
        isOutlined: true,
      ),
      title: Text(title),
      subtitle: Text(mimeType),
      isThreeLine: false,
      dense: true,
      horizontalTitleGap: 0,
      minVerticalPadding: 0,
      contentPadding: EdgeInsets.zero,
    );
    return Card(
        elevation: 0,
        child:
            tile); //SizedBox(height: 90, child: Card(elevation: 0, child: tile));
  }
}
