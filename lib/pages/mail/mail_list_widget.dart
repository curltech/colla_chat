import 'package:colla_chat/entity/mail/mail_message.dart';
import 'package:colla_chat/pages/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///邮件列表子视图
class MailListWidget extends StatelessWidget {
  const MailListWidget({super.key});

  ///当前邮箱邮件消息转换成tileData，如果为空则返回空列表
  Future<TileData?> findMailMessageTile(int index) async {
    List<MailMessage>? currentMailMessages =
        mailMimeMessageController.currentMailMessages;
    if (currentMailMessages == null || currentMailMessages.isEmpty) {
      await mailMimeMessageController.findMailMessages();
    }
    currentMailMessages = mailMimeMessageController.currentMailMessages;
    if (currentMailMessages == null) {
      return null;
    }

    return await _convertMimeMessage(currentMailMessages[index], index);
  }

  Future<TileData?> _convertMimeMessage(
      MailMessage mailMessage, int index) async {
    MailAddress? sender = mailMessage.decodeSender();
    var title = sender?.personalName;
    title = title ?? '';
    var email = sender?.email;
    email = email ?? '';
    title = '$title[$email]';
    var sendTime = mailMessage.sendTime;
    var titleTail = '';
    if (sendTime != null) {
      titleTail = DateUtil.formatEasyRead(sendTime);
    }
    var subtitle = mailMessage.subject;
    MimeMessage? mimeMessage =
        await mailMimeMessageController.convert(mailMessage);
    DecryptedMimeMessage? decryptedMimeMessage;
    dynamic prefix;
    if (mimeMessage != null) {
      decryptedMimeMessage =
          await mailMimeMessageController.decryptMimeMessage(mimeMessage);
      subtitle = decryptedMimeMessage.subject;
      if (decryptedMimeMessage.needDecrypt) {
        prefix = const Icon(
          Icons.mail_lock,
          color: Colors.yellow,
        );
      }
    } else {
      logger.e('convert mailMessage failure');
      prefix = const Icon(
        Icons.error_outline,
        color: Colors.red,
      );
    }
    TileData tile = TileData(
        prefix: prefix,
        title: title,
        titleTail: titleTail,
        subtitle: subtitle.toString(),
        selected: mailMimeMessageController.currentMailIndex == index);
    tile.slideActions = [
      TileData(
          prefix: Icons.delete,
          title: 'Delete',
          onTap: (int index, String title, {String? subtitle}) async {
            mailMimeMessageController.deleteMessage(index, expunge: false);
          }),
      TileData(
          prefix: Icons.mark_email_unread,
          title: 'Unread',
          onTap: (int index, String title, {String? subtitle}) async {
            mailMimeMessageController.flagMessage(index, isSeen: false);
          }),
      TileData(
          prefix: Icons.mark_email_read,
          title: 'Read',
          onTap: (int index, String title, {String? subtitle}) async {
            mailMimeMessageController.flagMessage(index, isSeen: true);
          }),
      TileData(
          prefix: Icons.flag,
          title: 'Flag',
          onTap: (int index, String title, {String? subtitle}) async {
            mailMimeMessageController.flagMessage(index, isFlagged: true);
          }),
      TileData(
          prefix: Icons.restore_from_trash,
          title: 'Junk',
          onTap: (int index, String title, {String? subtitle}) async {
            mailMimeMessageController.junkMessage(index);
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
          title: 'Forward',
          onTap: (int index, String title, {String? subtitle}) async {}),
    ];

    return tile;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) async {
    mailMimeMessageController.currentMailIndex.value = index;
    MailMessage? mailMessage = mailMimeMessageController.currentMailMessage;
    if (mailMessage == null) {
      return null;
    }
    if (mailMessage.status != FetchPreference.full.name) {
      MimeMessage? mimeMessage =
          await mailMimeMessageController.convert(mailMessage);
      if (mimeMessage != null) {
        await mailMimeMessageController.fetchMessageContents(mimeMessage);
        await mailMimeMessageController.findCurrent();
      }
    }

    indexWidgetProvider.push('mail_content');
  }

  Future<void> _onScrollMax() async {
    await mailMimeMessageController.findMailMessages();
  }

  Future<void> _onScrollMin() async {
    await mailMimeMessageController.fetchMessages();
    await mailMimeMessageController.findLatestMailMessages();
  }

  Future<void> _onRefresh() async {
    await mailMimeMessageController.fetchMessages();
    await mailMimeMessageController.findLatestMailMessages();
  }

  Widget _buildMailListWidget(BuildContext context) {
    List<MailMessage>? currentMailMessages =
        mailMimeMessageController.currentMailMessages;
    currentMailMessages ??= [];
    var dataListView = DataListView(
        onTap: _onTap,
        onScrollMax: _onScrollMax,
        onScrollMin: _onScrollMin,
        onRefresh: _onRefresh,
        itemCount: currentMailMessages.length,
        futureItemBuilder: (BuildContext context, int index) {
          return findMailMessageTile(index);
        });

    return dataListView;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mailMimeMessageController.currentMailIndex,
      builder: (BuildContext context, Widget? child) {
        return Obx(() {
          return _buildMailListWidget(context);
        });
      },
    );
  }
}
