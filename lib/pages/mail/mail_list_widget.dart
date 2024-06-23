import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';

///邮件列表子视图
class MailListWidget extends StatefulWidget {
  const MailListWidget({super.key});

  @override
  State<StatefulWidget> createState() => _MailListWidgetState();
}

class _MailListWidgetState extends State<MailListWidget> {
  @override
  initState() {
    mailMimeMessageController.addListener(_update);
    super.initState();
    mailMimeMessageController.findMoreMimeMessages();
  }

  _update() {
    setState(() {});
  }

  ///当前邮箱邮件消息转换成tileData，如果为空则返回空列表
  Future<List<TileData>> findMoreMimeMessageTiles() async {
    List<MimeMessage>? currentMimeMessages =
        mailMimeMessageController.currentMimeMessages;
    if (currentMimeMessages == null || currentMimeMessages.isEmpty) {
      await mailMimeMessageController.findMoreMimeMessages();
    }
    currentMimeMessages = mailMimeMessageController.currentMimeMessages;
    if (currentMimeMessages == null) {
      return [];
    }

    return await _convertMimeMessage(currentMimeMessages);
  }

  Future<List<TileData>> _convertMimeMessage(
      List<MimeMessage> mimeMessages) async {
    List<TileData> tiles = [];
    if (mimeMessages.isNotEmpty) {
      int i = 0;
      for (var mimeMessage in mimeMessages) {
        DecryptedMimeMessage decryptedMimeMessage =
            await mailMimeMessageController.decryptMimeMessage(mimeMessage);
        var title = decryptedMimeMessage.subject;
        Envelope? envelope = mimeMessage.envelope;
        if (envelope == null) {
          //logger.e('');
          continue;
        }
        title ??= mimeMessage.envelope?.subject;
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
            prefix: decryptedMimeMessage.needDecrypt ? Icons.mail_lock : null,
            title: title ?? '',
            titleTail: titleTail,
            subtitle: subtitle.toString(),
            selected: mailMimeMessageController.currentMailIndex == i);
        tile.slideActions = [
          TileData(
              prefix: Icons.delete,
              title: 'Delete',
              onTap: (int index, String title, {String? subtitle}) async {
                EmailClient? emailClient =
                    mailMimeMessageController.currentEmailClient;
                if (emailClient != null) {
                  emailClient.deleteMessage(mimeMessage, expunge: false);
                }
              }),
          TileData(
              prefix: Icons.mark_email_unread,
              title: 'Unread',
              onTap: (int index, String title, {String? subtitle}) async {
                EmailClient? emailClient =
                    mailMimeMessageController.currentEmailClient;
                if (emailClient != null) {
                  emailClient.flagMessage(mimeMessage, isSeen: false);
                }
              }),
          TileData(
              prefix: Icons.mark_email_read,
              title: 'Read',
              onTap: (int index, String title, {String? subtitle}) async {
                EmailClient? emailClient =
                    mailMimeMessageController.currentEmailClient;
                if (emailClient != null) {
                  emailClient.flagMessage(mimeMessage, isSeen: true);
                }
              }),
          TileData(
              prefix: Icons.flag,
              title: 'Flag',
              onTap: (int index, String title, {String? subtitle}) async {
                EmailClient? emailClient =
                    mailMimeMessageController.currentEmailClient;
                if (emailClient != null) {
                  emailClient.flagMessage(mimeMessage, isFlagged: true);
                }
              }),
          TileData(
              prefix: Icons.restore_from_trash,
              title: 'Junk',
              onTap: (int index, String title, {String? subtitle}) async {
                EmailClient? emailClient =
                    mailMimeMessageController.currentEmailClient;
                if (emailClient != null) {
                  emailClient.junkMessage(mimeMessage);
                }
              }),
        ];
        tile.endSlideActions = [
          TileData(
              prefix: Icons.reply,
              title: 'Reply',
              onTap: (int index, String title, {String? subtitle}) async {}),
          TileData(
              prefix: Icons.reply_all,
              title: 'Reply all',
              onTap: (int index, String title, {String? subtitle}) async {}),
          TileData(
              prefix: Icons.forward,
              title: 'Reply',
              onTap: (int index, String title, {String? subtitle}) async {}),
        ];

        tiles.add(tile);
        i++;
      }
    }

    return tiles;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) async {
    mailMimeMessageController.currentMailIndex = index;
    if (mailMimeMessageController.currentMimeMessage != null) {
      await mailMimeMessageController.fetchMessageContents();
    }
    indexWidgetProvider.push('mail_content');
  }

  Future<void> _onScrollMax() async {
    await mailMimeMessageController.findMoreMimeMessages();
  }

  Future<void> _onScrollMin() async {
    // await mailAddressController.findMoreMimeMessages();
  }

  Future<void> _onRefresh() async {
    await mailMimeMessageController.findMoreMimeMessages();
  }

  Widget _buildMailListWidget(BuildContext context) {
    var dataListView = FutureBuilder(
        future: findMoreMimeMessageTiles(),
        builder:
            (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
          if (!snapshot.hasData) {
            return LoadingUtil.buildLoadingIndicator();
          }
          List<TileData>? tiles = snapshot.data;
          if (tiles != null) {
            return DataListView(
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
    mailMimeMessageController.removeListener(_update);
    super.dispose();
  }
}
