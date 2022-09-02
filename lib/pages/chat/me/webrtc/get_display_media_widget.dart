import 'dart:core';

import 'package:colla_chat/pages/chat/me/webrtc/screen_select_dialog.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../l10n/localization.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../transport/webrtc/peer_video_render.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/app_bar_widget.dart';
import '../../../../widgets/common/widget_mixin.dart';

class GetDisplayMediaWidget extends StatefulWidget with TileDataMixin {
  const GetDisplayMediaWidget({Key? key}) : super(key: key);

  @override
  State createState() => _GetDisplayMediaWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'get_display_media';

  @override
  Icon get icon => const Icon(Icons.screen_rotation);

  @override
  String get title => 'GetDisplayMedia';
}

class _GetDisplayMediaWidgetState extends State<GetDisplayMediaWidget> {
  PeerVideoRender peerVideoRenderer = PeerVideoRender('');
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
      await peerVideoRenderer.createDisplayMedia(
          selectedSource: selectedSource);
      await peerVideoRenderer.enumerateDevices();
      await peerVideoRenderer.bindRTCVideoRender();
      var stream =
          await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
        'video': selectedSource == null
            ? true
            : {
                'deviceId': {'exact': selectedSource!.id},
                'mandatory': {'frameRate': 30.0}
              }
      });
      stream.getVideoTracks()[0].onEnded = () {
        logger.i(
            'By adding a listener on onEnded you can: 1) catch stop video sharing on Web');
      };
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
      peerVideoRenderer.dispose();
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
    return OrientationBuilder(
      builder: (context, orientation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(color: Colors.black),
            child: peerVideoRenderer.createVideoView(),
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
          color: appDataProvider.themeData!.colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
      title: Text(AppLocalizations.t(widget.title)),
      withLeading: widget.withLeading,
      rightPopupMenus: [_buildAppBarPopupMenu()],
      child: _buildVideoView(context),
    );
    return appBarView;
  }
}
