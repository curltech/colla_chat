import 'dart:core';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';

import '../../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../../transport/webrtc/base_peer_connection.dart';
import '../../../../widgets/common/widget_mixin.dart';

/// 连接建立示例
class PeerConnectionWidget extends StatefulWidget with TileDataMixin {
  final String? peerId;
  final String? clientId;
  final Room? room;
  final PeerConnectionPoolController controller = peerConnectionPoolController;

  PeerConnectionWidget({Key? key, this.room, this.peerId, this.clientId})
      : super(key: key);

  @override
  State createState() => _PeerConnectionWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_connection';

  @override
  Icon get icon => const Icon(Icons.screen_rotation);

  @override
  String get title => 'PeerConnection';
}

class _PeerConnectionWidgetState extends State<PeerConnectionWidget> {
  @override
  initState() {
    widget.controller.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  @override
  dispose() {
    //挂断
    widget.controller.removeListener(_update);
    super.dispose();
  }

  AdvancedPeerConnection? _getAdvancedPeerConnection() {
    AdvancedPeerConnection? advancedPeerConnection;
    if (widget.peerId != null) {
      advancedPeerConnection =
          peerConnectionPool.getOne(widget.peerId!, clientId: widget.clientId);
    }
    return null;
  }

  _open() async {
    try {
      AdvancedPeerConnection? advancedPeerConnection = await peerConnectionPool
          .create(widget.peerId!, clientId: widget.clientId);
    } catch (e) {
      logger.i(e.toString());
    }
    if (!mounted) return;

    //设置为连接状态
    setState(() {});
  }

  //关闭处理
  _close() async {
    try {
      peerConnectionPool.close(widget.peerId!, clientId: widget.clientId);
    } catch (e) {
      logger.i(e.toString());
    }
    //设置连接状态为false
    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    AdvancedPeerConnection? advancedPeerConnection =
        _getAdvancedPeerConnection();
    Widget? localView;
    Widget? remoteView;
    if (advancedPeerConnection != null) {
      localView = advancedPeerConnection
          .basePeerConnection!.localVideoRenders[0]!
          .createVideoView();
      remoteView = advancedPeerConnection
          .basePeerConnection!.remoteVideoRenders[0]!
          .createVideoView();
    }
    return OrientationBuilder(
      //orientation为旋转方向
      builder: (context, orientation) {
        //居中
        return Center(
          //容器
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Stack(
              children: <Widget>[
                Align(
                  //判断是否为垂直方向
                  alignment: orientation == Orientation.portrait
                      ? const FractionalOffset(0.5, 0.1)
                      : const FractionalOffset(0.0, 0.5),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: 320.0,
                    height: 240.0,
                    decoration: const BoxDecoration(color: Colors.black),
                    //本地视频渲染
                    child: localView,
                  ),
                ),
                Align(
                  //判断是否为垂直方向
                  alignment: orientation == Orientation.portrait
                      ? const FractionalOffset(0.5, 0.9)
                      : const FractionalOffset(1.0, 0.5),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: 320.0,
                    height: 240.0,
                    decoration: const BoxDecoration(color: Colors.black),
                    //远端视频渲染
                    child: remoteView,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(BuildContext context) {
    AdvancedPeerConnection? advancedPeerConnection =
        _getAdvancedPeerConnection();
    return IconButton(
      onPressed: advancedPeerConnection != null ? _close : _open,
      icon: Icon(advancedPeerConnection != null ? Icons.close : Icons.add),
    );
  }

  //重写 build方法
  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: AppLocalizations.t('video call'),
      withLeading: widget.withLeading,
      rightWidgets: [_buildIconButton(context)],
      child: _buildBody(context),
    );
  }
}
