import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_content_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_list_widget.dart';
import 'package:colla_chat/pages/chat/mail/new_mail_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///邮件应用总体视图，由三个子视图组成
///第一个是邮件地址视图，列出邮件地址的列表和邮件地址下的目录结构
///第二个是邮件列表视图，列出邮件地址目录下的邮件列表，在窄屏时的缺省进入视图
///第一个和第二个视图合用一个视图展示，宽屏时在body部分展示，邮件列表视图的左上角有按钮，弹出邮件地址视图对话框
///第三个是邮件内容视图，显示邮件的具体内容，在secondary body部分展示
class MailWidget extends StatefulWidget with TileDataMixin {
  final MailAddressWidget mailAddressWidget = MailAddressWidget();
  final MailListWidget mailListWidget = const MailListWidget();
  final MailContentWidget mailContentWidget = const MailContentWidget();
  final NewMailWidget newMailWidget = const NewMailWidget();

  MailWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(mailContentWidget);
    indexWidgetProvider.define(newMailWidget);
  }

  @override
  State<StatefulWidget> createState() => _MailWidgetState();

  @override
  String get routeName => 'mail';

  @override
  bool get withLeading => false;

  @override
  IconData get iconData => Icons.email;

  @override
  String get title => 'Mail';
}

class _MailWidgetState extends State<MailWidget> {
  ValueNotifier<bool> addressVisible = ValueNotifier<bool>(false);
  ValueNotifier<String> mailboxName = ValueNotifier<String>('');

  @override
  initState() {
    mailAddressController.addListener(_update);
    super.initState();
    mailAddressController.findAllMailAddress();
  }

  _update() {
    EmailAddress? current = mailAddressController.current;
    String email = current?.email ?? '';
    String? name = mailAddressController.currentMailboxName;
    if (name == null) {
      mailboxName.value = email;
    } else {
      mailboxName.value = '$email($name)';
    }
  }

  Widget _buildPlatformDrawer() {
    Widget view = Stack(children: [
      widget.mailListWidget,
      ValueListenableBuilder(
          valueListenable: addressVisible,
          builder: (BuildContext context, bool addressVisible, Widget? child) {
            return Visibility(
                visible: addressVisible,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                          elevation: 0.0,
                          shape: const ContinuousRectangleBorder(),
                          margin: EdgeInsets.zero,
                          child: SizedBox(
                              width: 280,
                              height: double.infinity,
                              child: widget.mailAddressWidget)),
                      Expanded(
                          child: GestureDetector(
                              onTap: () {
                                this.addressVisible.value = false;
                              },
                              child: Container(
                                color: Colors.black.withOpacity(0.4),
                              ))),
                    ]));
          }),
    ]);

    return view;
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (appDataProvider.smallBreakpoint.isActive(context)) {
      body = _buildPlatformDrawer();
    } else {
      body = _buildPlatformDrawer();
    }
    List<Widget> rightWidgets = [
      IconButton(
          tooltip: AppLocalizations.t('Toggle mail address view'),
          onPressed: () {
            addressVisible.value = !addressVisible.value;
          },
          icon: addressVisible.value
              ? const Icon(Icons.toggle_off)
              : const Icon(Icons.toggle_on)),
    ];
    if (addressVisible.value) {
      rightWidgets.add(IconButton(
          onPressed: () {
            indexWidgetProvider.push('mail_address_auto_discover');
          },
          icon: const Icon(Icons.auto_mode),
          tooltip: AppLocalizations.t('Auto discover address')));
      rightWidgets.add(IconButton(
          onPressed: () {
            indexWidgetProvider.push('mail_address_manual_add');
          },
          icon: const Icon(Icons.handyman),
          tooltip: AppLocalizations.t('Manual add address')));
    } else {
      rightWidgets.add(IconButton(
          onPressed: () {
            indexWidgetProvider.push('new_mail');
          },
          icon: const Icon(Icons.note_add),
          tooltip: AppLocalizations.t('New mail')));
    }
    Widget titleWidget = ValueListenableBuilder(
        valueListenable: mailboxName,
        builder: (BuildContext context, String mailboxName, Widget? child) {
          return CommonAutoSizeText(
            mailboxName,
            style: const TextStyle(fontSize: AppFontSize.smFontSize),
          );
        });
    var appBarView = AppBarView(
        titleWidget: titleWidget,
        withLeading: widget.withLeading,
        rightWidgets: rightWidgets,
        child: body);

    return appBarView;
  }

  @override
  void dispose() {
    mailAddressController.removeListener(_update);
    super.dispose();
  }
}
