import 'dart:core';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 连接建立示例
class DataChannelWidget extends StatefulWidget with TileDataMixin {
  DataChannelWidget({Key? key}) : super(key: key);

  @override
  State createState() => _DataChannelWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_channel';

  @override
  IconData get iconData => Icons.screen_rotation;

  @override
  String get title => 'DataChannel';
}

class _DataChannelWidgetState extends State<DataChannelWidget> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController peerIdController = TextEditingController();
  final TextEditingController clientIdController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  String? message;
  String peerId = '';
  String clientId = '';
  String? roomId;
  AdvancedPeerConnection? advancedPeerConnection;

  @override
  initState() {
    peerIdController.text = '53HWCVP2BJX8LZ7BLfKEgQGpisNQXcKBfVLhkMEvZ3Zr';
    clientIdController.text = 'EepCRDBTjwPM4c1Jh34G6qeFRf59NgTDpz2QVapJzdBU';
    super.initState();
  }

  _update() {
    setState(() {});
  }

  @override
  dispose() {
    super.dispose();
  }

  _open() async {
    peerId = peerIdController.text;
    clientId = clientIdController.text;

    try {
      advancedPeerConnection =
          await peerConnectionPool.create(peerId, clientId: clientId);
    } catch (e) {
      logger.i(e.toString());
    }
    if (!mounted) return;

    //设置为连接状态
    setState(() {});
  }

  //发送消息
  _sendMessage() async {
    if (advancedPeerConnection != null) {
      var msg = CryptoUtil.stringToUtf8(messageController.text);
      await advancedPeerConnection!.send(Uint8List.fromList(msg));
      messageController.clear();
    }
  }

  //关闭处理
  _close() async {
    try {
      peerConnectionPool.close(peerId, clientId: clientId);
    } catch (e) {
      logger.i(e.toString());
    }
    //设置连接状态为false
    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    var view = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CommonTextFormField(
          controller: roomController,
          labelText: 'room',
        ),
        CommonTextFormField(
          controller: peerIdController,
          labelText: 'peerId',
        ),
        CommonTextFormField(
          controller: clientIdController,
          labelText: 'clientId',
        ),
        const SizedBox(
          height: 35.0,
        ),
        CommonAutoSizeText(
          '接收到的消息:$message',
        ),
        CommonTextFormField(
          controller: messageController,
          labelText: 'message',
        ),
        TextButton(
          child: const CommonAutoSizeText('点击发送文本'),
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
    return IconButton(
      onPressed: advancedPeerConnection != null ? _close : _open,
      icon: Icon(advancedPeerConnection != null ? Icons.close : Icons.add),
    );
  }

  //重写 build方法
  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: [_buildIconButton(context)],
      child: _buildBody(context),
    );
  }
}
