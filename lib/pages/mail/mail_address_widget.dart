import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/entity/mail/mail_address.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/mail/address/auto_discover_widget.dart';
import 'package:colla_chat/pages/mail/address/email_service_provider.dart';
import 'package:colla_chat/pages/mail/address/manual_add_widget.dart';
import 'package:colla_chat/pages/mail/mail_content_widget.dart';
import 'package:colla_chat/pages/mail/mail_list_widget.dart';
import 'package:colla_chat/pages/mail/mail_mime_message_controller.dart';
import 'package:colla_chat/pages/mail/new_mail_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/mail/mail_address.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///邮件地址子视图
class MailAddressWidget extends StatelessWidget with TileDataMixin {
  final AutoDiscoverWidget autoDiscoverWidget = AutoDiscoverWidget();
  final ManualAddWidget manualAddWidget = ManualAddWidget();
  final MailContentWidget mailContentWidget = MailContentWidget();
  final NewMailWidget newMailWidget = NewMailWidget();

  final MailListWidget mailListWidget = MailListWidget();

  MailAddressWidget({super.key}) {
    platformEmailServiceProvider.init();
    indexWidgetProvider.define(autoDiscoverWidget);
    indexWidgetProvider.define(manualAddWidget);
    indexWidgetProvider.define(mailContentWidget);
    indexWidgetProvider.define(newMailWidget);
  }

  @override
  String get routeName => 'mail_address';

  @override
  bool get withLeading => false;

  @override
  IconData get iconData => Icons.mail;

  @override
  String get title {
    return 'Mail';
  }

  final RxInt index = 0.obs;
  final PlatformCarouselController controller = PlatformCarouselController();

  void _onTap(int index, String title, {String? subtitle, TileData? group}) {
    int i = 0;
    for (MailAddress emailAddress in mailAddressController.data) {
      if (emailAddress.email == group!.title) {
        mailAddressController.setCurrentIndex = i;
        break;
      }
      i++;
    }
    mailboxController.setCurrentMailbox(title);
    controller.move(0);
  }

  Widget _buildMailAddressWidget(BuildContext context) {
    Map<TileData, List<TileData>> mailAddressTileData = {};
    var mailAddresses = mailAddressController.data;
    if (mailAddresses.isNotEmpty) {
      int i = 0;
      for (var mailAddress in mailAddresses) {
        TileData groupTile = TileData(
            title: mailAddress.email,
            subtitle: mailAddress.name,
            prefix: IconButton(
              onPressed: () {
                int index = i;
                int? id = mailAddress.id;
                if (id != null) {
                  mailAddressService.delete(where: 'id=?', whereArgs: [id]);
                  mailAddressController.delete(index: index);
                  emailClientPool.close(email: mailAddress.email);
                }
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: AppLocalizations.t('Delete'),
            ),
            selected: mailAddressController.currentIndex.value == i);
        List<TileData> tiles = [];
        List<String>? mailboxNames =
            mailboxController.getMailboxNames(mailAddress.email);

        if (mailboxNames != null && mailboxNames.isNotEmpty) {
          String? currentMailboxName = mailboxController.currentMailboxName;
          for (var mailboxName in mailboxNames) {
            Icon icon = Icon(mailboxController.findDirectoryIcon(mailboxName));
            enough_mail.Mailbox? mailbox =
                mailboxController.getMailbox(mailAddress.email, mailboxName);
            String titleTail = '';
            if (mailbox != null) {
              titleTail = '${mailbox.messagesUnseen}/${mailbox.messagesExists}';
            }
            TileData tile = TileData(
                title: mailboxName,
                prefix: icon,
                titleTail: titleTail,
                selected: mailAddressController.currentIndex == i &&
                    currentMailboxName == mailboxName);
            tiles.add(tile);
          }
        }
        mailAddressTileData[groupTile] = tiles;
        i++;
      }
    }
    var mailAddressWidget = GroupDataListView(
      tileData: mailAddressTileData,
      onTap: _onTap,
    );

    return mailAddressWidget;
  }

  String getMailboxName() {
    MailAddress? current = mailAddressController.current;
    String email = current?.email ?? AppLocalizations.t('No address');
    String? name = mailboxController.currentMailboxName;
    if (name == null) {
      return email;
    } else {
      return '$email(${AppLocalizations.t(name)})';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> toolBars = [];
    toolBars.add(IconButton(
        onPressed: () {
          indexWidgetProvider.push('mail_address_auto_discover');
        },
        icon: Icon(Icons.auto_mode, color: myself.primary),
        tooltip: AppLocalizations.t('Auto discover address')));
    toolBars.add(IconButton(
        onPressed: () {
          indexWidgetProvider.push('mail_address_manual_add');
        },
        icon: Icon(Icons.handyman, color: myself.primary),
        tooltip: AppLocalizations.t('Manual add address')));
    toolBars.add(IconButton(
        onPressed: () {
          mailMimeMessageController.fetchMessages();
        },
        icon: Icon(Icons.refresh, color: myself.primary),
        tooltip: AppLocalizations.t('Refresh')));
    toolBars.add(IconButton(
        onPressed: () {
          indexWidgetProvider.push('new_mail');
        },
        icon: Icon(Icons.note_add, color: myself.primary),
        tooltip: AppLocalizations.t('New mail')));
    Widget titleWidget = InkWell(
        onTap: () {
          controller.move(1);
        },
        child: AutoSizeText(
          getMailboxName(),
          style: const TextStyle(color: Colors.black),
          softWrap: true,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ));
    toolBars.add(Spacer());
    toolBars.add(titleWidget);
    var appBarView = PlatformCarouselWidget(
        itemCount: 2,
        initialPage: index.value,
        controller: controller,
        onPageChanged: (int index,
            {PlatformSwiperDirection? direction,
              int? oldIndex,
              CarouselPageChangedReason? reason}) {
          this.index.value = index;
        },
        itemBuilder: (BuildContext context, int index, {int? realIndex}) {
          if (index == 1) {
            return _buildMailAddressWidget(context);
          }
          return mailListWidget;
        });

    return Column(
      children: [
        Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(),
            child: Row(
              children: toolBars,
            )),
        Expanded(child: appBarView)
      ],
    );
  }
}
