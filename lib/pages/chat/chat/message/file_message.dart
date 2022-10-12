import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:mimecon/mimecon.dart';

///消息体：文件消息
class FileMessage extends StatelessWidget {
  final String title;
  final String mimeType;
  final List<int> data;
  final bool isMyself;

  const FileMessage(
      {Key? key,
      required this.data,
      required this.isMyself,
      required this.title,
      required this.mimeType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var tile = InkWell(
      onTap: () {},
      child: ListTile(
        leading: Mimecon(
          mimetype: mimeType,
          color: appDataProvider.themeData.colorScheme.primary,
          size: 36,
        ),
        title: Text(title),
        subtitle: Text(mimeType),
      ),
    );
    return SizedBox(height: 90, child: Card(elevation: 0, child: tile));
  }
}
