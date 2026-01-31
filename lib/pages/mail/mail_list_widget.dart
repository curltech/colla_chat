import 'package:colla_chat/entity/mail/mail_message.dart';
import 'package:colla_chat/pages/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///邮件列表子视图
class MailListWidget extends StatelessWidget {
  final List<ActionData> mailPopActionData = [];

  MailListWidget({super.key}) {
    _initMailActionData();
  }

  ///当前邮箱邮件消息转换成tileData，如果为空则返回空列表
  Future<DataTile?> findMailMessageTile(int index) async {
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

  void _initMailActionData() {
    mailPopActionData
        .add(ActionData(icon: const Icon(Icons.delete), label: 'Delete'));
    mailPopActionData.add(ActionData(
      icon: const Icon(Icons.mark_email_unread),
      label: 'Unread',
    ));
    mailPopActionData.add(ActionData(
      icon: const Icon(Icons.mark_email_read),
      label: 'Read',
    ));
    mailPopActionData.add(ActionData(
      icon: const Icon(Icons.flag),
      label: 'Flag',
    ));
    mailPopActionData.add(ActionData(
      icon: const Icon(Icons.restore_from_trash),
      label: 'Junk',
    ));
    mailPopActionData.add(ActionData(
      icon: const Icon(Icons.reply),
      label: 'Reply',
    ));
    mailPopActionData.add(ActionData(
      icon: const Icon(Icons.reply_all),
      label: 'Reply all',
    ));
    mailPopActionData.add(ActionData(
      icon: const Icon(Icons.forward),
      label: 'Forward',
    ));
  }

  Future<void> _onMailPopAction(BuildContext context, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'Delete':
        mailMimeMessageController.deleteMessage(index, expunge: false);
        break;
      case 'Unread':
        mailMimeMessageController.flagMessage(index, isSeen: false);
        break;
      case 'Read':
        mailMimeMessageController.flagMessage(index, isSeen: true);
        break;
      case 'Flag':
        mailMimeMessageController.flagMessage(index, isFlagged: true);
        break;
      case 'Junk':
        mailMimeMessageController.junkMessage(index);
        break;
      case 'Reply':
        break;
      case 'Reply all':
        break;
      case 'Forward':
        break;
      default:
        break;
    }
  }

  Future<void> _showMailPopAction({BuildContext? context}) async {
    await DialogUtil.show(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            elevation: 0.0,
            insetPadding: EdgeInsets.zero,
            child: DataActionCard(
                onPressed: (int index, String label, {String? value}) {
                  Navigator.pop(context);
                  _onMailPopAction(context, index, label, value: value);
                },
                crossAxisCount: 4,
                actions: mailPopActionData,
                height: 200,
                width: appDataProvider.secondaryBodyWidth,
                iconSize: 30));
      },
    );
  }

  Future<DataTile?> _convertMimeMessage(
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
        if (mailMessage.status == FetchPreference.envelope.name) {
          prefix = const Icon(
            Icons.mail_lock,
            color: Colors.yellow,
          );
        }
        if (mailMessage.status == FetchPreference.full.name) {
          prefix = Icon(
            Icons.mail_lock,
            color: myself.primary,
          );
        }
      } else {
        if (mailMessage.status == FetchPreference.envelope.name) {
          prefix = const Icon(
            Icons.mail,
            color: Colors.yellow,
          );
        }
        if (mailMessage.status == FetchPreference.full.name) {
          prefix = Icon(
            Icons.mail,
            color: myself.primary,
          );
        }
      }
    } else {
      logger.e('convert mailMessage failure');
      prefix = const Icon(
        Icons.error_outline,
        color: Colors.red,
      );
    }
    DataTile tile = DataTile(
      prefix: prefix,
      title: title,
      titleTail: titleTail,
      subtitle: subtitle.toString(),
      selected: mailMimeMessageController.currentMailIndex.value == index,
      onLongPress: (int index, String title, {String? subtitle}) async {
        _showMailPopAction();
        return null;
      },
    );

    return tile;
  }

  Future<Null> _onTap(int index, String title, {String? subtitle, DataTile? group}) async {
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
