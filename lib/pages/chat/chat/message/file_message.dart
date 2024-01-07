import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';

///消息体：文件消息
class FileMessage extends StatelessWidget {
  final String title;
  final String mimeType;
  final String messageId;
  final bool isMyself;

  const FileMessage(
      {super.key,
      required this.messageId,
      required this.isMyself,
      required this.title,
      required this.mimeType});

  @override
  Widget build(BuildContext context) {
    String? mimeType = FileUtil.mimeType(title);
    var tileData = TileData(
      prefix: Mimecon(
        mimetype: mimeType ?? this.mimeType,
        color: myself.primary,
        size: 36,
        isOutlined: true,
      ),
      title: title,
      subtitle: mimeType,
      dense: true,
    );
    return CommonMessage(tileData: tileData);
  }
}
