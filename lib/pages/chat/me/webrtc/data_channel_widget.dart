import 'dart:core';
import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';

import '../../../../provider/app_data_provider.dart';
import '../../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../../transport/webrtc/base_peer_connection.dart';
import '../../../../widgets/common/widget_mixin.dart';

/// 连接建立示例
class DataChannelWidget extends StatefulWidget with TileDataMixin {
  final String? peerId;
  final String? clientId;
  final Room? room;
  final PeerConnectionPoolController controller = peerConnectionPoolController;

  DataChannelWidget({Key? key, this.room, this.peerId, this.clientId})
      : super(key: key);

  @override
  State createState() => _DataChannelWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_channel';

  @override
  Icon get icon => const Icon(Icons.screen_rotation);

  @override
  String get title => 'DataChannel';
}

class _DataChannelWidgetState extends State<DataChannelWidget> {
  final TextEditingController textEditingController = TextEditingController();
  String? message;
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

  _open() async {
    try {
      AdvancedPeerConnection? advancedPeerConnection = await peerConnectionPool
          .create(widget.peerId!, widget.clientId!, getUserMedia: true);
      if (advancedPeerConnection != null) {
        await advancedPeerConnection.init(
            widget.peerId!, widget.clientId!, true);
        advancedPeerConnection.basePeerConnection
            .on(WebrtcEventType.data, _onMessage);
      }
    } catch (e) {
      logger.i(e.toString());
    }
    if (!mounted) return;

    //设置为连接状态
    setState(() {});
  }

  _onMessage(Uint8List data) {
    message = String.fromCharCodes(data);
    _update();
  }

  //发送消息
  _sendMessage() {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(widget.peerId!, widget.clientId!);
    advancedPeerConnection!.basePeerConnection
        .send(Uint8List.fromList(textEditingController.text.codeUnits));
    textEditingController.clear();
  }

  //关闭处理
  _close() async {
    try {
      peerConnectionPool.remove(widget.peerId!, clientId: widget.clientId);
    } catch (e) {
      logger.i(e.toString());
    }
    //设置连接状态为false
    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(widget.peerId!, widget.clientId!);
    var view = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '接收到的消息:$message',
        ),
        TextFormField(
          controller: textEditingController,
          autofocus: true,
        ),
        TextButton(
          child: const Text('点击发送文本'),
          onPressed: () {
            _sendMessage();
          },
        ),
      ],
    );
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
                    child: view,
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
        peerConnectionPool.getOne(widget.peerId!, widget.clientId!);
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
