import 'package:colla_chat/plugin/talker_logger.dart' as log;
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart' as livekit_client;

/// 媒体流绑定渲染器，并创建展示视图
class PeerMediaRenderView extends StatefulWidget {
  final PeerMediaStream peerMediaStream;
  final RTCVideoViewObjectFit objectFit;
  final bool mirror;
  final FilterQuality filterQuality;
  final bool fitScreen;
  final double? width;
  final double? height;
  final Color? color;

  const PeerMediaRenderView({
    super.key,
    required this.peerMediaStream,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    this.mirror = false,
    this.filterQuality = FilterQuality.low,
    this.fitScreen = false,
    this.width,
    this.height,
    this.color = Colors.black,
  });

  @override
  State createState() => _PeerMediaRenderViewState();
}

class _PeerMediaRenderViewState extends State<PeerMediaRenderView> {
  RTCVideoRenderer? renderer;
  ValueNotifier<bool> readyRenderer = ValueNotifier<bool>(false);

  @override
  initState() {
    super.initState();
    bindRTCVideoRender();
  }

  //绑定视频流到渲染器
  bindRTCVideoRender() async {
    MediaStream? mediaStream = widget.peerMediaStream.mediaStream;
    if (mediaStream != null) {
      renderer = RTCVideoRenderer();
      await renderer!.initialize();
      renderer!.srcObject = mediaStream;
    }
    readyRenderer.value = true;
  }

  close() {
    var renderer = this.renderer;
    renderer?.srcObject = null;
    try {
      renderer?.dispose();
    } catch (e) {
      log.logger.e('renderer.dispose failure:$e');
    }
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
    Widget? videoView;
    var renderer = this.renderer;
    videoView = ValueListenableBuilder(
        valueListenable: readyRenderer,
        builder: (BuildContext context, bool readyRenderer, Widget? child) {
          if (readyRenderer) {
            if (renderer != null) {
              return RTCVideoView(renderer,
                  objectFit: widget.objectFit,
                  mirror: widget.mirror,
                  filterQuality: widget.filterQuality);
            } else {
              livekit_client.VideoTrack? videoTrack =
                  widget.peerMediaStream.videoTrack;
              livekit_client.AudioTrack? audioTrack =
                  widget.peerMediaStream.audioTrack;
              if (videoTrack != null) {
                return livekit_client.VideoTrackRenderer(
                  videoTrack,
                  fit: widget.objectFit,
                  mirrorMode: widget.mirror
                      ? livekit_client.VideoViewMirrorMode.mirror
                      : livekit_client.VideoViewMirrorMode.off,
                );
              } else if (audioTrack != null) {
                return const Center(
                    child: Icon(
                  Icons.multitrack_audio_outlined,
                  color: Colors.white,
                  size: 60,
                ));
              }
            }
          }
          return LoadingUtil.buildCircularLoadingWidget();
        });

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
    close();
    super.dispose();
  }
}
