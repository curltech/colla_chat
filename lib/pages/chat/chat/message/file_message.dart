import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/open_file.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';
import 'package:open_filex/open_filex.dart';

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
        onTap: (int index, String title, {String? subtitle}) async {
          String? filename = await messageAttachmentService.getDecryptFilename(
              messageId, title);
          if (filename != null) {
            OpenResult result = await OpenFileUtil.open(filename);
            ResultType resultType = result.type;
            if (resultType != ResultType.done) {
              logger.e(
                  'open file $filename failure:$resultType.name, ${result.message}');
              DialogUtil.error(context,
                  content:
                      'open file $filename failure:$resultType.name, ${result.message}');
            }
          }
        });
    return CommonMessage(tileData: tileData);
  }
}
