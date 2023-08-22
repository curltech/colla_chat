import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

/// 媒体流绑定渲染器，并创建展示视图
class LiveKitMediaRenderView extends StatefulWidget {
  final VideoTrack videoTrack;
  final RTCVideoViewObjectFit objectFit;
  final bool mirror;
  final FilterQuality filterQuality;
  final bool fitScreen;
  final double? width;
  final double? height;
  final Color? color;
  final bool audio;
  final bool video;

  const LiveKitMediaRenderView({
    super.key,
    required this.videoTrack,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    this.mirror = false,
    this.filterQuality = FilterQuality.low,
    this.fitScreen = false,
    this.width,
    this.height,
    this.audio = true,
    this.video = true,
    this.color = Colors.black,
  });

  @override
  State createState() => _LiveKitMediaRenderViewState();
}

class _LiveKitMediaRenderViewState extends State<LiveKitMediaRenderView> {
  @override
  initState() {
    super.initState();
  }

  Widget _buildVideoViewContainer(Widget? child,
      {double? width, double? height}) {
    child ??= emptyVideoView;
    Widget container = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      height = height ?? constraints.maxHeight;
      width = width ?? constraints.maxWidth;
      return Center(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          width: width,
          height: height,
          decoration: BoxDecoration(color: widget.color),
          child: child,
        ),
      );
    });

    return container;
  }

  /// 创建展示视图，纯音频显示图标
  Widget _buildVideoView() {
    Widget? videoView = VideoTrackRenderer(widget.videoTrack,
        fit: widget.objectFit,
        mirrorMode: widget.mirror
            ? VideoViewMirrorMode.mirror
            : VideoViewMirrorMode.off);

    if (widget.audio && !widget.video) {
      videoView = Stack(children: [
        const Center(
            child: Icon(
          Icons.multitrack_audio_outlined,
          color: Colors.white,
          size: 60,
        )),
        videoView,
      ]);
    }
    Widget container = _buildVideoViewContainer(videoView,
        width: widget.width, height: widget.height);
    if (!widget.fitScreen) {
      return container;
    }

    //用屏幕尺寸
    return OrientationBuilder(
      builder: (context, orientation) {
        var width = MediaQuery.of(context).size.width;
        var height = MediaQuery.of(context).size.height;
        container = _buildVideoViewContainer(
          videoView,
          width: width,
          height: height,
        );
        return container;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoView();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
