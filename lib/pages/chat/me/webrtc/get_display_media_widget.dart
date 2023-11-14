import 'dart:core';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_media_render_view.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class GetDisplayMediaWidget extends StatefulWidget with TileDataMixin {
  const GetDisplayMediaWidget({Key? key}) : super(key: key);

  @override
  State createState() => _GetDisplayMediaWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'get_display_media';

  @override
  IconData get iconData => Icons.screen_rotation;

  @override
  String get title => 'GetDisplayMedia';
}

class _GetDisplayMediaWidgetState extends State<GetDisplayMediaWidget> {
  PeerMediaStream peerMediaStream = PeerMediaStream();
  bool _inCalling = false;
  DesktopCapturerSource? selectedSource;

  @override
  void initState() {
    super.initState();
  }

  Future<void> selectScreenSourceDialog(BuildContext context) async {
    final source = await showDialog<DesktopCapturerSource>(
      context: context,
      builder: (context) => ScreenSelectDialog(),
    );
    if (source != null) {
      await _makeCall(source);
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _makeCall(DesktopCapturerSource source) async {
    setState(() {
      selectedSource = source;
    });

    try {
      peerMediaStream = await PeerMediaStream.createLocalDisplayMedia(
          selectedSource: selectedSource);
      // var stream =
      //     await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
      //   'video': selectedSource == null
      //       ? true
      //       : {
      //           'deviceId': {'exact': selectedSource!.id},
      //           'mandatory': {'frameRate': 30.0}
      //         }
      // });
      // stream.getVideoTracks()[0].onEnded = () {
      //   logger.i(
      //       'By adding a listener on onEnded you can: 1) catch stop video sharing on Web');
      // };
    } catch (e) {
      logger.e(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  void _hangUp() async {
    try {
      peerMediaStream.close();
      setState(() {
        _inCalling = false;
      });
    } catch (e) {
      logger.e(e.toString());
    }
  }

  void _selectSource() async {
    await selectScreenSourceDialog(context);
  }

  Widget _buildVideoView(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return OrientationBuilder(
      builder: (context, orientation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
            width: width,
            height: height,
            decoration: const BoxDecoration(color: Colors.black),
            child: P2pMediaRenderView(
              peerMediaStream: peerMediaStream,
              width: width,
              height: height,
            ),
          ),
        );
      },
    );
  }

  AppBarPopupMenu _buildAppBarPopupMenu() {
    return AppBarPopupMenu(
      onPressed: _inCalling ? _hangUp : _selectSource,
      title: _inCalling ? 'Hangup' : 'Call',
      icon: Icon(_inCalling ? Icons.call_end : Icons.phone,
          color: myself.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightPopupMenus: [_buildAppBarPopupMenu()],
      child: _buildVideoView(context),
    );
    return appBarView;
  }
}
