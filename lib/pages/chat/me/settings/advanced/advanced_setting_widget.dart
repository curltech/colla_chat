import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/ws_address_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/brightness_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/color_picker.dart';
import 'package:colla_chat/pages/chat/me/settings/general/locale_picker.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 高级设置组件，包括定位器配置
class AdvancedSettingWidget extends StatefulWidget with TileDataMixin {
  final PeerEndpointListWidget peerEndpointListWidget =
      PeerEndpointListWidget();
  final PeerClientListWidget peerClientListWidget = PeerClientListWidget();
  late final List<TileData> advancedSettingTileData;

  AdvancedSettingWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(peerEndpointListWidget);
    indexWidgetProvider.define(peerClientListWidget);
    List<TileDataMixin> mixins = [
      peerEndpointListWidget,
      peerClientListWidget,
    ];
    advancedSettingTileData = TileData.from(mixins);
    for (var tile in advancedSettingTileData) {
      tile.dense = true;
    }
  }

  @override
  State<StatefulWidget> createState() => _AdvancedSettingWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'advanced_setting';

  @override
  Icon get icon => const Icon(Icons.settings_suggest);

  @override
  String get title => 'Advanced Setting';
}

class _AdvancedSettingWidgetState extends State<AdvancedSettingWidget> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildSettingWidget(BuildContext context) {
    Widget child = DataListView(tileData: widget.advancedSettingTileData);
    var padding = const EdgeInsets.symmetric(horizontal: 15.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 30.0),
        Padding(
          padding: padding,
          child: const WsAddressPicker(),
        ),
        const SizedBox(height: 10.0),
        child
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: Text(AppLocalizations.t(widget.title)),
        child: _buildSettingWidget(context));
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
