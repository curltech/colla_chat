import 'package:colla_chat/pages/chat/me/android_system_alert_window_widget.dart';
import 'package:colla_chat/pages/chat/me/openvpn_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_map_launcher_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/pages/game/game_main_widget.dart';
import 'package:colla_chat/pages/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/media/media_widget.dart';
import 'package:colla_chat/pages/poem/poem_widget.dart';
import 'package:colla_chat/pages/stock/stock_main_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/sherpa/sherpa_install_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//其他的应用的页面，带有路由回调函数
class OtherAppWidget extends StatelessWidget with TileDataMixin {
  final MediaWidget mediaWidget = MediaWidget();
  final PlatformWebViewWidget webViewWidget = PlatformWebViewWidget();
  final OpenVpnWidget openVpnWidget = const OpenVpnWidget();
  final SystemAlertWindowWidget systemAlertWindowWidget =
      const SystemAlertWindowWidget();
  final PlatformMapLauncherWidget platformMapLauncherWidget =
      PlatformMapLauncherWidget();
  final SherpaInstallWidget sherpaInstallWidget = SherpaInstallWidget();
  final MailAddressWidget mailAddressWidget = MailAddressWidget();
  final StockMainWidget stockMainWidget = StockMainWidget();
  final GameMainWidget gameMainWidget = GameMainWidget();
  final PoemWidget poemWidget = PoemWidget();

  late Map<String, TileDataMixin> widgets = {
    poemWidget.routeName: poemWidget,
    stockMainWidget.routeName: stockMainWidget,
    gameMainWidget.routeName: gameMainWidget,
    mailAddressWidget.routeName: mailAddressWidget,
    mediaWidget.routeName: mediaWidget,
    webViewWidget.routeName: webViewWidget,
    openVpnWidget.routeName: openVpnWidget,
    systemAlertWindowWidget.routeName: systemAlertWindowWidget,
    platformMapLauncherWidget.routeName: platformMapLauncherWidget,
    sherpaInstallWidget.routeName: sherpaInstallWidget,
  };

  OtherAppWidget({super.key}) {
    indexWidgetProvider.define(webViewWidget);
    indexWidgetProvider.define(openVpnWidget);
    indexWidgetProvider.define(systemAlertWindowWidget);
    indexWidgetProvider.define(platformMapLauncherWidget);
    indexWidgetProvider.define(sherpaInstallWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'other_app';

  @override
  IconData get iconData => Icons.apps;

  @override
  String get title => 'Other app';

  late final RxString name = routeName.obs;

  Widget _buildOtherAppTileData(BuildContext context) {
    List<TileData> otherAppTileData = [];
    otherAppTileData.add(TileData(
        title: poemWidget.title,
        prefix: poemWidget.iconData,
        onTap: (int index, String title, {String? subtitle}) {
          name.value = poemWidget.routeName;
        }));
    final bool emailSwitch = myself.peerProfile.emailSwitch;
    if (emailSwitch) {
      otherAppTileData.add(TileData(
          title: mailAddressWidget.title,
          prefix: mailAddressWidget.iconData,
          onTap: (int index, String title, {String? subtitle}) {
            name.value = mailAddressWidget.routeName;
          }));
    }
    final bool stockSwitch = myself.peerProfile.stockSwitch;
    if (stockSwitch) {
      otherAppTileData.add(TileData(
          title: stockMainWidget.title,
          prefix: stockMainWidget.iconData,
          onTap: (int index, String title, {String? subtitle}) {
            name.value = stockMainWidget.routeName;
          }));
    }
    final bool gameSwitch = myself.peerProfile.gameSwitch;
    if (gameSwitch) {
      otherAppTileData.add(TileData(
          title: gameMainWidget.title,
          prefix: gameMainWidget.iconData,
          onTap: (int index, String title, {String? subtitle}) {
            name.value = gameMainWidget.routeName;
          }));
    }

    otherAppTileData.add(TileData(
        title: mediaWidget.title,
        prefix: mediaWidget.iconData,
        onTap: (int index, String title, {String? subtitle}) {
          name.value = mediaWidget.routeName;
        }));
    otherAppTileData.add(TileData(
        title: webViewWidget.title,
        prefix: webViewWidget.iconData,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(webViewWidget.routeName);
        }));
    otherAppTileData.add(TileData(
        title: platformMapLauncherWidget.title,
        prefix: platformMapLauncherWidget.iconData,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(platformMapLauncherWidget.routeName);
        }));
    otherAppTileData.add(TileData(
        title: sherpaInstallWidget.title,
        prefix: sherpaInstallWidget.iconData,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(sherpaInstallWidget.routeName);
        }));

    if (platformParams.mobile) {
      if (myself.peerProfile.vpnSwitch) {
        otherAppTileData.add(TileData(
            title: openVpnWidget.title,
            prefix: openVpnWidget.iconData,
            onTap: (int index, String title, {String? subtitle}) {
              indexWidgetProvider.push(openVpnWidget.routeName);
            }));
      }
      if (platformParams.android) {
        if (myself.peerProfile.developerSwitch) {
          otherAppTileData.add(TileData(
              title: systemAlertWindowWidget.title,
              prefix: systemAlertWindowWidget.iconData,
              onTap: (int index, String title, {String? subtitle}) {
                indexWidgetProvider.push(systemAlertWindowWidget.routeName);
              }));
        }
      }
    }

    Widget otherAppWidget = DataListView(
      itemCount: otherAppTileData.length,
      itemBuilder: (BuildContext context, int index) {
        return otherAppTileData[index];
      },
    );

    return otherAppWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Widget? rightWidget = IconButton(
          onPressed: () {
            name.value = routeName;
          },
          icon: const Icon(Icons.arrow_back_ios));
      String title = this.title;
      Widget otherAppWidget = _buildOtherAppTileData(context);
      Widget child;
      TileDataMixin? current = widgets[name.value];
      if (current == null) {
        rightWidget = null;
        child = otherAppWidget;
      } else {
        title = current.title;
        child = current as Widget;
      }
      var otherApp =
          AppBarView(title: title, rightWidget: rightWidget, child: child);

      return otherApp;
    });
  }
}
