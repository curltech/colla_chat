import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/mobile_system_alert_window_widget.dart';
import 'package:colla_chat/pages/chat/me/openvpn_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_map_launcher_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_widget.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_system_widget.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_widget.dart';
import 'package:colla_chat/pages/game/game_widget.dart';
import 'package:colla_chat/pages/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/media/media_widget.dart';
import 'package:colla_chat/pages/pip/mobile_pip_widget.dart';
import 'package:colla_chat/pages/poem/poem_widget.dart';
import 'package:colla_chat/pages/stock/stock_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/overlay/flutter_floating_widget.dart';
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
  final MobileSystemAlertWindowWidget mobileSystemAlertWindowWidget =
      MobileSystemAlertWindowWidget();
  final FlutterFloatingWidget flutterFloatingWidget = FlutterFloatingWidget();
  final PlatformMapLauncherWidget platformMapLauncherWidget =
      PlatformMapLauncherWidget();
  final SherpaInstallWidget sherpaInstallWidget = SherpaInstallWidget();
  final MailAddressWidget mailAddressWidget = MailAddressWidget();
  final StockMainWidget stockMainWidget = StockMainWidget();
  final MobilePipWidget mobilePipWidget = MobilePipWidget();
  final GameMainWidget gameMainWidget = GameMainWidget();
  final PoemWidget poemWidget = PoemWidget();
  final DataSourceWidget dataSourceWidget = DataSourceWidget();
  final FileSystemWidget fileSystemWidget = FileSystemWidget();
  final FileWidget fileWidget = FileWidget();

  late final Map<String, TileDataMixin> widgets = {
    poemWidget.routeName: poemWidget,
    stockMainWidget.routeName: stockMainWidget,
    gameMainWidget.routeName: gameMainWidget,
    mailAddressWidget.routeName: mailAddressWidget,
    mediaWidget.routeName: mediaWidget,
    webViewWidget.routeName: webViewWidget,
    openVpnWidget.routeName: openVpnWidget,
    mobileSystemAlertWindowWidget.routeName: mobileSystemAlertWindowWidget,
    flutterFloatingWidget.routeName: flutterFloatingWidget,
    mobilePipWidget.routeName: mobilePipWidget,
    platformMapLauncherWidget.routeName: platformMapLauncherWidget,
    sherpaInstallWidget.routeName: sherpaInstallWidget,
    dataSourceWidget.routeName: dataSourceWidget,
    fileSystemWidget.routeName: fileSystemWidget,
  };

  OtherAppWidget({super.key}) {
    indexWidgetProvider.define(webViewWidget);
    indexWidgetProvider.define(openVpnWidget);
    indexWidgetProvider.define(mobileSystemAlertWindowWidget);
    indexWidgetProvider.define(flutterFloatingWidget);
    indexWidgetProvider.define(mobilePipWidget);
    indexWidgetProvider.define(platformMapLauncherWidget);
    indexWidgetProvider.define(sherpaInstallWidget);
    indexWidgetProvider.define(fileWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'other_app';

  @override
  IconData get iconData => Icons.apps;

  @override
  String get title => 'Apps';

  late final RxString name = routeName.obs;

  Widget _buildOtherAppTileData(BuildContext context) {
    List<TileData> otherAppTileData = [];
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(poemWidget.title),
        prefix: poemWidget.iconData,
        helpPath: poemWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          name.value = poemWidget.routeName;
        }));
    final bool emailSwitch = myself.peerProfile.emailSwitch;
    if (emailSwitch) {
      otherAppTileData.add(TileData(
          title: AppLocalizations.t(mailAddressWidget.title),
          prefix: mailAddressWidget.iconData,
          helpPath: mailAddressWidget.routeName,
          onTap: (int index, String title, {String? subtitle}) {
            name.value = mailAddressWidget.routeName;
          }));
    }
    final bool stockSwitch = myself.peerProfile.stockSwitch;
    if (stockSwitch) {
      otherAppTileData.add(TileData(
          title: AppLocalizations.t(stockMainWidget.title),
          prefix: stockMainWidget.iconData,
          helpPath: stockMainWidget.routeName,
          onTap: (int index, String title, {String? subtitle}) {
            name.value = stockMainWidget.routeName;
          }));
    }
    final bool gameSwitch = myself.peerProfile.gameSwitch;
    if (gameSwitch) {
      otherAppTileData.add(TileData(
          title: AppLocalizations.t(gameMainWidget.title),
          prefix: gameMainWidget.iconData,
          helpPath: gameMainWidget.routeName,
          onTap: (int index, String title, {String? subtitle}) {
            name.value = gameMainWidget.routeName;
          }));
    }

    otherAppTileData.add(TileData(
        title: AppLocalizations.t(mediaWidget.title),
        prefix: mediaWidget.iconData,
        helpPath: mediaWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          name.value = mediaWidget.routeName;
        }));
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(webViewWidget.title),
        prefix: webViewWidget.iconData,
        helpPath: webViewWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(webViewWidget.routeName);
        }));
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(platformMapLauncherWidget.title),
        prefix: platformMapLauncherWidget.iconData,
        helpPath: platformMapLauncherWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(platformMapLauncherWidget.routeName);
        }));
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(sherpaInstallWidget.title),
        prefix: sherpaInstallWidget.iconData,
        helpPath: sherpaInstallWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(sherpaInstallWidget.routeName);
        }));
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(flutterFloatingWidget.title),
        prefix: flutterFloatingWidget.iconData,
        helpPath: flutterFloatingWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(flutterFloatingWidget.routeName);
        }));
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(mobilePipWidget.title),
        prefix: mobilePipWidget.iconData,
        helpPath: mobilePipWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          indexWidgetProvider.push(mobilePipWidget.routeName);
        }));
    if (platformParams.mobile) {
      if (myself.peerProfile.vpnSwitch) {
        otherAppTileData.add(TileData(
            title: AppLocalizations.t(openVpnWidget.title),
            prefix: openVpnWidget.iconData,
            helpPath: openVpnWidget.routeName,
            onTap: (int index, String title, {String? subtitle}) {
              indexWidgetProvider.push(openVpnWidget.routeName);
            }));
      }
      if (myself.peerProfile.developerSwitch) {
        otherAppTileData.add(TileData(
            title: AppLocalizations.t(mobileSystemAlertWindowWidget.title),
            prefix: mobileSystemAlertWindowWidget.iconData,
            helpPath: mobileSystemAlertWindowWidget.routeName,
            onTap: (int index, String title, {String? subtitle}) {
              indexWidgetProvider.push(mobileSystemAlertWindowWidget.routeName);
            }));
      }
    }
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(dataSourceWidget.title),
        prefix: dataSourceWidget.iconData,
        helpPath: dataSourceWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          name.value = dataSourceWidget.routeName;
        }));
    otherAppTileData.add(TileData(
        title: AppLocalizations.t(fileSystemWidget.title),
        prefix: fileSystemWidget.iconData,
        helpPath: fileSystemWidget.routeName,
        onTap: (int index, String title, {String? subtitle}) {
          name.value = fileSystemWidget.routeName;
        }));

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
      Widget? backWidget;
      String title = this.title;
      Widget otherAppWidget = _buildOtherAppTileData(context);
      Widget child;
      TileDataMixin? current = widgets[name.value];
      if (current == null) {
        backWidget = null;
        child = otherAppWidget;
      } else {
        title = current.title;
        child = current as Widget;
        backWidget = IconButton(
            onPressed: () {
              name.value = routeName;
            },
            icon: const Icon(Icons.arrow_back_ios_new));
      }
      var otherApp = AppBarView(
          title: title,
          helpPath: current?.routeName,
          leadingWidget: backWidget,
          child: child);

      return otherApp;
    });
  }
}
