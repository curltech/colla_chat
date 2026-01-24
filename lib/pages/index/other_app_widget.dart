import 'package:colla_chat/pages/chat/me/openvpn_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_map_launcher_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_widget.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_system_widget.dart';
import 'package:colla_chat/pages/game/game_widget.dart';
import 'package:colla_chat/pages/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/media/media_widget.dart';
import 'package:colla_chat/pages/poem/poem_widget.dart';
import 'package:colla_chat/pages/stock/stock_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/overlay/flutter_overlay_window.dart';
import 'package:colla_chat/plugin/pip/flutter_pip_window_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
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
  final FlutterOverlayWindowWidget flutterOverlayWindowWidget =
      FlutterOverlayWindowWidget();
  final PlatformMapLauncherWidget platformMapLauncherWidget =
      PlatformMapLauncherWidget();
  final MailAddressWidget mailAddressWidget = MailAddressWidget();
  final StockMainWidget stockMainWidget = StockMainWidget();
  final FlutterPipWindowWidget flutterPipWindowWidget =
      FlutterPipWindowWidget();
  final GameMainWidget gameMainWidget = GameMainWidget();
  final PoemWidget poemWidget = PoemWidget();
  final DataSourceWidget dataSourceWidget = DataSourceWidget();
  final FileSystemWidget fileSystemWidget = FileSystemWidget();

  OtherAppWidget({super.key}) {
    indexWidgetProvider.define(mediaWidget);
    indexWidgetProvider.define(webViewWidget);
    indexWidgetProvider.define(mailAddressWidget);
    indexWidgetProvider.define(stockMainWidget);
    indexWidgetProvider.define(gameMainWidget);
    indexWidgetProvider.define(poemWidget);
    indexWidgetProvider.define(openVpnWidget);
    indexWidgetProvider.define(flutterOverlayWindowWidget);
    indexWidgetProvider.define(flutterPipWindowWidget);
    indexWidgetProvider.define(platformMapLauncherWidget);
    indexWidgetProvider.define(dataSourceWidget);
    indexWidgetProvider.define(fileSystemWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'other_app';

  @override
  IconData get iconData => Icons.apps;

  @override
  String get title => 'Apps';

  /// 用于制定在body部分显示的页面
  late final RxString name = routeName.obs;

  /// 修改name的值，从body的页面转向新的body页面
  List<TileData> _buildOtherAppTileData(BuildContext context) {
    List<TileDataMixin> mixins = [
      poemWidget,
    ];
    final bool emailSwitch = myself.peerProfile.emailSwitch;
    if (emailSwitch) {
      mixins.add(mailAddressWidget);
    }
    final bool stockSwitch = myself.peerProfile.stockSwitch;
    if (stockSwitch) {
      mixins.add(stockMainWidget);
    }
    final bool gameSwitch = myself.peerProfile.gameSwitch;
    if (gameSwitch) {
      mixins.add(gameMainWidget);
    }
    mixins.add(mediaWidget);
    mixins.add(webViewWidget);
    mixins.add(platformMapLauncherWidget);
    mixins.add(flutterPipWindowWidget);
    if (platformParams.mobile) {
      if (myself.peerProfile.vpnSwitch) {
        mixins.add(openVpnWidget);
      }
    }
    if (myself.peerProfile.developerSwitch) {
      mixins.add(flutterOverlayWindowWidget);
    }
    mixins.add(dataSourceWidget);
    mixins.add(fileSystemWidget);
    List<TileData> otherAppTileData = TileData.from(mixins);
    for (var tile in otherAppTileData) {
      tile.dense = false;
      tile.selected = false;
    }

    return otherAppTileData;
  }

  @override
  Widget build(BuildContext context) {
    List<TileData> otherAppTileData = _buildOtherAppTileData(context);
    Widget child = DataListView(
      itemCount: otherAppTileData.length,
      itemBuilder: (BuildContext context, int index) {
        return otherAppTileData[index];
      },
    );

    var otherApp = AppBarView(title: title, helpPath: routeName, child: child);

    return otherApp;
  }
}
