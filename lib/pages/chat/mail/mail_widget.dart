import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_content_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_list_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
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
  final SwiperController controller = SwiperController();

  MailWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(mailContentWidget);
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
  @override
  initState() {
    widget.controller.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var view = Swiper(
        itemCount: 2,
        controller: widget.controller,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return widget.mailAddressWidget;
          }
          if (index == 1) {
            return widget.mailListWidget;
          }
          return Container();
        });
    List<Widget> rightWidgets = [
      IconButton(
          onPressed: () {
            widget.controller.index = widget.controller.index == 0 ? 1 : 0;
            widget.controller.next();
          },
          icon: const Icon(Icons.menu)),
    ];
    if (widget.controller.index == 0) {
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
    }
    if (widget.controller.index == 1) {
      rightWidgets.add(IconButton(
          onPressed: () {
            indexWidgetProvider.push('mail_address_manual_add');
          },
          icon: const Icon(Icons.edit_note),
          tooltip: AppLocalizations.t('New mail')));
    }
    var appBarView = AppBarView(
        title: widget.controller.index == 0 ? 'Mail address' : 'Mail list',
        withLeading: widget.withLeading,
        rightWidgets: rightWidgets,
        child: view);

    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
