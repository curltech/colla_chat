import 'package:colla_chat/entity/mail/mail_message.dart';
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
    super.initState();
    mailMimeMessageController.addListener(_update);
    mailMimeMessageController.findMailMessages();
  }

  _update() {
    setState(() {});
  }

  ///当前邮箱邮件消息转换成tileData，如果为空则返回空列表
  Future<List<TileData>> findMoreMimeMessageTiles() async {
    List<MailMessage>? currentMailMessages =
        mailMimeMessageController.currentMailMessages;
    if (currentMailMessages == null || currentMailMessages.isEmpty) {
      await mailMimeMessageController.findMailMessages();
    }
    currentMailMessages = mailMimeMessageController.currentMailMessages;
    if (currentMailMessages == null) {
      return [];
    }

    return await _convertMimeMessage(currentMailMessages);
  }

  Future<List<TileData>> _convertMimeMessage(
      List<MailMessage> mailMessages) async {
    List<TileData> tiles = [];
    if (mailMessages.isNotEmpty) {
      int i = 0;
      for (var mailMessage in mailMessages) {
        MimeMessage mimeMessage =
            mailMimeMessageController.convert(mailMessage)!;
        DecryptedMimeMessage decryptedMimeMessage =
            await mailMimeMessageController.decryptMimeMessage(mimeMessage);
        var subtitle = decryptedMimeMessage.subject;
        var title = mailMessage.sender?.personalName;
        title = title ?? '';
        var email = mailMessage.sender?.email;
        email = email ?? '';
        title = '$title[$email]';
        var sendDate = mailMessage.sendTime;
        var titleTail = '';
        if (sendDate != null) {
          titleTail = DateUtil.formatEasyRead(sendDate);
        }
        TileData tile = TileData(
            prefix: decryptedMimeMessage.needDecrypt ? Icons.mail_lock : null,
            title: title,
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
    if (mailMimeMessageController.currentMailMessage != null) {
      MimeMessage? mimeMessage = mailMimeMessageController
          .convert(mailMimeMessageController.currentMailMessage!);
      if (mimeMessage != null) {
        await mailMimeMessageController.fetchMessageContents(mimeMessage);
      }
    }
    indexWidgetProvider.push('mail_content');
  }

  Future<void> _onScrollMax() async {
    await mailMimeMessageController.fetchMessages();
    await mailMimeMessageController.findLatestMailMessages();
  }

  Future<void> _onScrollMin() async {
    List<MailMessage>? currentMailMessages =
        mailMimeMessageController.currentMailMessages;
    if (currentMailMessages != null && currentMailMessages.isNotEmpty) {
      MimeMessage? mimeMessage =
          mailMimeMessageController.convert(currentMailMessages.last);
      if (mimeMessage != null) {
        await mailMimeMessageController.fetchMessagesNextPage(mimeMessage);
      }
    }
    await mailMimeMessageController.findMailMessages();
  }

  Future<void> _onRefresh() async {
    await mailMimeMessageController.fetchMessages();
    await mailMimeMessageController.findLatestMailMessages();
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
