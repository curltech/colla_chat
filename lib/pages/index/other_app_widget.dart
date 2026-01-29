import 'package:colla_chat/pages/chat/me/openvpn_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_map_launcher_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_widget.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_system_widget.dart';
import 'package:colla_chat/pages/game/game_widget.dart';
import 'package:colla_chat/pages/game/mahjong/mahjong_18m_widget.dart';
import 'package:colla_chat/pages/game/model/meta_modeller_widget.dart';
import 'package:colla_chat/pages/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/media/platform_audio_player_widget.dart';
import 'package:colla_chat/pages/media/platform_audio_recorder_widget.dart';
import 'package:colla_chat/pages/media/platform_video_player_widget.dart';
import 'package:colla_chat/pages/poem/poem_widget.dart';
import 'package:colla_chat/pages/stock/stock_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/overlay/flutter_overlay_window.dart';
import 'package:colla_chat/plugin/pip/flutter_pip_window_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_media_widget.dart';
import 'package:colla_chat/widgets/media_editor/image_editor_widget.dart';
import 'package:colla_chat/widgets/media_editor/video_editor_widget.dart';
import 'package:colla_chat/widgets/media_editor/video_renderer_widget.dart';
import 'package:flutter/material.dart';

//其他的应用的页面，带有路由回调函数
class OtherAppWidget extends StatelessWidget with TileDataMixin {
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

  final PlatformVideoPlayerWidget videoPlayerWidget =
      PlatformVideoPlayerWidget();
  final PlatformAudioPlayerWidget audioPlayerWidget =
      PlatformAudioPlayerWidget();
  final PlatformAudioRecorderWidget audioRecorderWidget =
      PlatformAudioRecorderWidget();
  final FFMpegMediaWidget ffmpegMediaWidget = FFMpegMediaWidget();
  final ImageEditorWidget imageEditorWidget = ImageEditorWidget();
  final VideoEditorWidget videoEditorWidget = VideoEditorWidget();
  final VideoRendererWidget videoRendererWidget = VideoRendererWidget();

  late final List<TileDataMixin> mediaTileDataMixins = [
    videoPlayerWidget,
    audioPlayerWidget,
    audioRecorderWidget,
    imageEditorWidget,
    ffmpegMediaWidget,
    videoEditorWidget,
    videoRendererWidget
  ];
  final Majiang18mWidget mahjong18mWidget = Majiang18mWidget();
  final MetaModellerWidget metaModellerWidget = MetaModellerWidget();

  final Map<TileData, List<TileData>> otherAppTileData = {};

  OtherAppWidget({super.key}) {
    indexWidgetProvider.define(videoPlayerWidget);
    indexWidgetProvider.define(audioPlayerWidget);
    indexWidgetProvider.define(audioRecorderWidget);
    indexWidgetProvider.define(imageEditorWidget);
    indexWidgetProvider.define(ffmpegMediaWidget);
    indexWidgetProvider.define(videoEditorWidget);
    indexWidgetProvider.define(videoRendererWidget);
    List<TileData> mediaTileData = TileData.from(mediaTileDataMixins);
    otherAppTileData[TileData(title: 'Media', prefix: Icons.perm_media)] =
        mediaTileData;

    indexWidgetProvider.define(webViewWidget);
    otherAppTileData[TileData.of(webViewWidget)] = [];

    indexWidgetProvider.define(mailAddressWidget);
    final bool emailSwitch = myself.peerProfile.emailSwitch;
    if (emailSwitch) {
      otherAppTileData[TileData.of(mailAddressWidget)] = [];
    }
    indexWidgetProvider.define(stockMainWidget);
    final bool stockSwitch = myself.peerProfile.stockSwitch;
    if (stockSwitch) {
      otherAppTileData[TileData.of(stockMainWidget)] = [];
    }
    indexWidgetProvider.define(mahjong18mWidget);
    indexWidgetProvider.define(metaModellerWidget);
    final bool gameSwitch = myself.peerProfile.gameSwitch;
    if (gameSwitch) {
      List<TileData> gameTileData =
          TileData.from([mahjong18mWidget, metaModellerWidget]);
      otherAppTileData[TileData(title: 'Game', prefix: Icons.games_outlined)] =
          gameTileData;
    }

    indexWidgetProvider.define(poemWidget);
    otherAppTileData[TileData.of(poemWidget)] = [];
    indexWidgetProvider.define(openVpnWidget);
    if (platformParams.mobile) {
      if (myself.peerProfile.vpnSwitch) {
        otherAppTileData[TileData.of(openVpnWidget)] = [];
      }
    }
    indexWidgetProvider.define(flutterOverlayWindowWidget);
    if (myself.peerProfile.developerSwitch) {
      otherAppTileData[TileData.of(flutterOverlayWindowWidget)] = [];
    }
    indexWidgetProvider.define(flutterPipWindowWidget);
    otherAppTileData[TileData.of(flutterPipWindowWidget)] = [];
    indexWidgetProvider.define(platformMapLauncherWidget);
    otherAppTileData[TileData.of(platformMapLauncherWidget)] = [];
    indexWidgetProvider.define(dataSourceWidget);
    otherAppTileData[TileData.of(dataSourceWidget)] = [];
    indexWidgetProvider.define(fileSystemWidget);
    otherAppTileData[TileData.of(fileSystemWidget)] = [];
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'other_app';

  @override
  IconData get iconData => Icons.apps;

  @override
  String get title => 'Apps';

  Map<TileData, List<TileData>> _buildOtherAppTileData(BuildContext context) {
    return {};
  }

  @override
  Widget build(BuildContext context) {
    Widget child = GroupDataListView(
      tileData: otherAppTileData,
    );

    var otherApp = AppBarView(title: title, helpPath: routeName, child: child);

    return otherApp;
  }
}
