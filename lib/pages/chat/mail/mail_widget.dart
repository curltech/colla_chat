import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_controller.dart';
import 'package:colla_chat/pages/chat/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_content_widget.dart';
import 'package:colla_chat/pages/chat/mail/mail_list_widget.dart';
import 'package:colla_chat/pages/chat/mail/new_mail_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:draggable_home/draggable_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';

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
  final AdvancedDrawerController controller = AdvancedDrawerController();

  @override
  initState() {
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
    mailAddressController.refresh();
  }

  AdvancedDrawer _buildAdvancedDrawer() {
    AdvancedDrawer advancedDrawer = AdvancedDrawer(
      backdropColor: Colors.white.withOpacity(0),
      openRatio: 0.6,
      openScale: 1,
      controller: controller,
      drawer: controller.value.visible ? widget.mailAddressWidget : Container(),
      child: widget.mailListWidget,
    );

    return advancedDrawer;
  }

  SlidingUpPanel _buildSlidingUpPanel() {
    SlidingUpPanel slidingUpPanel = SlidingUpPanel(
      panelBuilder: () {
        return widget.mailListWidget;
      },
      body: widget.mailAddressWidget,
    );

    return slidingUpPanel;
  }

  DraggableHome _buildDraggableHome() {
    DraggableHome draggableHome = DraggableHome(
      fullyStretchable: true,
      title: const Text('Title'),
      leading: const Icon(Icons.arrow_back_ios),
      expandedBody: const Text('Expanded Body'),
      headerBottomBar: const Text('HeaderBottomBar'),
      headerWidget: widget.mailListWidget,
      body: [widget.mailAddressWidget],
    );

    return draggableHome;
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (appDataProvider.smallBreakpoint.isActive(context)) {
      body = _buildAdvancedDrawer(); //_buildDraggableHome();
    } else {
      body = _buildAdvancedDrawer();
    }
    //open ? controller.showDrawer() : controller.hideDrawer();
    List<Widget> rightWidgets = [
      IconButton(
          onPressed: () {
            controller.toggleDrawer();
          },
          icon: const Icon(Icons.menu)),
    ];
    if (controller.value.visible) {
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
          icon: const Icon(Icons.edit_note),
          tooltip: AppLocalizations.t('New mail')));
    }
    EmailAddress? current = mailAddressController.current;
    String? currentMailboxName = mailAddressController.currentMailboxName;
    String? title = 'Mail list';
    if (current != null) {
      title = current.email;
      if (currentMailboxName != null) {
        title = '$title($currentMailboxName)';
      }
    }
    var appBarView = AppBarView(
        title: controller.value.visible ? 'Mail address' : title,
        withLeading: widget.withLeading,
        rightWidgets: rightWidgets,
        child: body);

    return appBarView;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
