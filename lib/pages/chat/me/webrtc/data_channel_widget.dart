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
  final PeerConnectionPoolController controller = peerConnectionPoolController;

  DataChannelWidget({Key? key}) : super(key: key);

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
  final TextEditingController messageController = TextEditingController();
  final TextEditingController peerIdController = TextEditingController();
  final TextEditingController clientIdController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  String? message = '';
  String? peerId = '';
  String? clientId = '';
  String? roomId = '';

  @override
  initState() {
    widget.controller.addListener(_update);
    //当被叫服务器创建的时候回调
    peerConnectionPool.on(WebrtcEventType.create, _onCreate);
    peerIdController.text = 'GyStWSnwg4mQqzS4S3bTpEKX72CJPpKkz91ESatiMy7G';
    clientIdController.text = 'EepCRDBTjwPM4c1Jh34G6qeFRf59NgTDpz2QVapJzdBU';
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

  _onCreate(WebrtcEvent evt) {
    peerId = evt.peerId;
    clientId = evt.clientId;
    peerIdController.text = peerId!;
    clientIdController.text = clientId!;
    AdvancedPeerConnection advancedPeerConnection =
        evt.data as AdvancedPeerConnection;
    advancedPeerConnection.basePeerConnection
        .on(WebrtcEventType.message, _onMessage);
    _update();
  }

  AdvancedPeerConnection? _getAdvancedPeerConnection() {
    AdvancedPeerConnection? advancedPeerConnection;
    if (peerId != null) {
      advancedPeerConnection =
          peerConnectionPool.getOne(peerId!, clientId: clientId);
    }
    return null;
  }

  _open() async {
    peerId = peerIdController.text;
    clientId = clientIdController.text;

    try {
      AdvancedPeerConnection? advancedPeerConnection = await peerConnectionPool
          .create(peerId!, clientId!, getUserMedia: false);
      if (advancedPeerConnection != null) {
        await advancedPeerConnection.init(peerId!, clientId!, true);
        advancedPeerConnection.basePeerConnection
            .on(WebrtcEventType.message, _onMessage);
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
        _getAdvancedPeerConnection();
    if (advancedPeerConnection != null) {
      advancedPeerConnection!.basePeerConnection
          .send(Uint8List.fromList(messageController.text.codeUnits));
      messageController.clear();
    }
  }

  //关闭处理
  _close() async {
    try {
      peerConnectionPool.remove(peerId!, clientId: clientId);
    } catch (e) {
      logger.i(e.toString());
    }
    //设置连接状态为false
    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    AdvancedPeerConnection? advancedPeerConnection =
        _getAdvancedPeerConnection();
    var view = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: roomController,
          decoration: const InputDecoration(labelText: 'room'),
        ),
        TextFormField(
          controller: peerIdController,
          decoration: const InputDecoration(labelText: 'peerId'),
        ),
        TextFormField(
          controller: clientIdController,
          decoration: const InputDecoration(labelText: 'clientId'),
        ),
        const SizedBox(
          height: 35.0,
        ),
        Text(
          '接收到的消息:$message',
        ),
        TextFormField(
          controller: messageController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'message'),
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
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                      width: 520.0,
                      height: 400.0,
                      //decoration: const BoxDecoration(color: Colors.black),
                      //本地视频渲染
                      child: view,
                    )),
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
      title: AppLocalizations.t(widget.title),
      withLeading: widget.withLeading,
      rightWidgets: [_buildIconButton(context)],
      child: _buildBody(context),
    );
  }
}
