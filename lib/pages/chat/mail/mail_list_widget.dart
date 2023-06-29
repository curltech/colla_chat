import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';

///邮件列表子视图
class MailListWidget extends StatefulWidget {
  const MailListWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MailListWidgetState();
}

class _MailListWidgetState extends State<MailListWidget> {
  @override
  initState() {
    mailAddressController.addListener(_update);
    mailAddressController.findMoreMimeMessages();
    super.initState();
  }

  _update() {
    setState(() {});
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    mailAddressController.currentMailIndex = index;
    indexWidgetProvider.push('mail_content');
  }

  List<TileData> _convertMimeMessage(List<MimeMessage> mimeMessages) {
    List<TileData> tiles = [];
    if (mimeMessages.isNotEmpty) {
      for (var mimeMessage in mimeMessages) {
        var title = mimeMessage.envelope?.subject;
        var subtitle = mimeMessage.envelope?.sender?.personalName;
        subtitle = subtitle ?? '';
        var email = mimeMessage.envelope?.sender?.email;
        email = email ?? '';
        subtitle = '$subtitle[$email]';
        var sendDate = mimeMessage.envelope?.date;
        var titleTail = '';
        if (sendDate != null) {
          titleTail = DateUtil.formatEasyRead(sendDate.toIso8601String());
        }
        TileData tile = TileData(
            title: title ?? '',
            titleTail: titleTail,
            subtitle: subtitle.toString());
        tiles.add(tile);
      }
    }

    return tiles;
  }

  Widget _buildMailListWidget(BuildContext context) {
    List<MimeMessage>? currentMimeMessages =
        mailAddressController.currentMimeMessages;
    if (currentMimeMessages != null) {
      var tiles = _convertMimeMessage(currentMimeMessages);
      var dataListView = DataListView(onTap: _onTap, tileData: tiles);

      return dataListView;
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return _buildMailListWidget(context);
  }

  @override
  void dispose() {
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
