import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
    super.initState();
    mailAddressController.findMoreMimeMessages();
  }

  _update() {
    setState(() {});
  }

  Future<List<MimeMessage>?> findMoreMimeMessages() async {
    List<MimeMessage>? currentMimeMessages =
        mailAddressController.currentMimeMessages;
    if (currentMimeMessages == null || currentMimeMessages.isEmpty) {
      await mailAddressController.findMoreMimeMessages();
    }
    currentMimeMessages = mailAddressController.currentMimeMessages;

    return currentMimeMessages;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    mailAddressController.currentMailIndex = index;
    indexWidgetProvider.push('mail_content');
  }

  List<TileData> _convertMimeMessage(List<MimeMessage> mimeMessages) {
    List<TileData> tiles = [];
    if (mimeMessages.isNotEmpty) {
      int i = 0;
      for (var mimeMessage in mimeMessages) {
        Envelope? envelope = mimeMessage.envelope;
        if (envelope == null) {
          //logger.e('');
          continue;
        }
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
            subtitle: subtitle.toString(),
            selected: mailAddressController.currentMailIndex == i);
        tiles.add(tile);
        i++;
      }
    }

    return tiles;
  }

  Future<void> _onScrollMax() async {
    await mailAddressController.findMoreMimeMessages();
  }

  Future<void> _onScrollMin() async {
    // await mailAddressController.findMoreMimeMessages();
  }

  Future<void> _onRefresh() async {
    await mailAddressController.findMoreMimeMessages();
  }

  Widget _buildMailListWidget(BuildContext context) {
    var dataListView = FutureBuilder(
        future: findMoreMimeMessages(),
        builder:
            (BuildContext context, AsyncSnapshot<List<MimeMessage>?> snapshot) {
          if (!snapshot.hasData) {
            return LoadingUtil.buildLoadingIndicator();
          }
          List<MimeMessage>? mimeMessages = snapshot.data;
          if (mimeMessages != null) {
            var tiles = _convertMimeMessage(mimeMessages);

            return DataListView(
                reverse: true,
                onTap: _onTap,
                tileData: tiles,
                onScrollMax: _onScrollMax,
                onScrollMin: _onScrollMin,
                onRefresh: _onRefresh);
          }

          return Center(
              child: CommonAutoSizeText(
                  AppLocalizations.t('Have no MimeMessages')));
        });

    return dataListView;
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
