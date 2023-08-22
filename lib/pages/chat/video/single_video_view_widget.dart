import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_media_render_view.dart';
import 'package:colla_chat/transport/webrtc/p2p/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

///单个小视频窗口，显示一个视频流的PeerpeerMediaStream，长按出现更大的窗口，带有操作按钮
class SingleVideoViewWidget extends StatefulWidget {
  final PeerMediaStreamController peerMediaStreamController;
  final Conference? conference;
  final PeerMediaStream peerMediaStream;
  final double? height;
  final double? width;
  final Function(PeerMediaStream peerMediaStream) onClosed;

  const SingleVideoViewWidget({
    Key? key,
    required this.peerMediaStreamController,
    required this.onClosed,
    this.conference,
    required this.peerMediaStream,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  State createState() => _SingleVideoViewWidgetState();
}

class _SingleVideoViewWidgetState extends State<SingleVideoViewWidget> {
  bool enableFullScreen = false;
  bool enableMute = false;
  bool enableSpeaker = false;
  bool enableTorch = false;
  double volume = 1;

  late OverlayEntry _popupDialog;

  @override
  initState() {
    super.initState();
    widget.peerMediaStreamController.registerPeerMediaStreamOperator(
        PeerMediaStreamOperator.selected.name, _updateSelected);
    widget.peerMediaStreamController.registerPeerMediaStreamOperator(
        PeerMediaStreamOperator.unselected.name, _updateSelected);
  }

  Future<void> _updateSelected(PeerMediaStream? peerMediaStream) async {
    if (widget.peerMediaStream.id != null &&
        peerMediaStream != null &&
        peerMediaStream.id == widget.peerMediaStream.id) {
      setState(() {});
    }
  }

  OverlayEntry _buildPopupDialog() {
    return OverlayEntry(
      builder: (context) => AnimatedContain(
        child: _buildPopupVideoView(),
      ),
    );
  }

  Widget _buildPopupVideoView() {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    Widget mediaRenderView = P2pMediaRenderView(
        mediaStream: widget.peerMediaStream.mediaStream!, height: height, width: width);
    Widget singleVideoView = Builder(
      builder: (context) => InkWell(
        onLongPress: () async {
          await _showActionCard(context);
        },
        child: mediaRenderView,
      ),
    );

    return singleVideoView;
  }

  List<ActionData> _buildVideoActionData() {
    List<ActionData> videoActionData = [];
    if (widget.peerMediaStreamController.currentPeerMediaStream != null) {
      videoActionData.add(
        ActionData(
            label: 'Camera switch',
            //actionType: ActionType.inkwell,
            icon: const Icon(Icons.cameraswitch)),
      );
    }
    if (enableSpeaker) {
      videoActionData.add(
        ActionData(
            label: 'Microphone switch',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.mic_rounded)),
      );
    } else {
      videoActionData.add(
        ActionData(
            label: 'Speaker switch',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.speaker_phone)),
      );
    }
    if (volume < 1) {
      videoActionData.add(
        ActionData(
            label: 'Volume increase',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.volume_up)),
      );
    }
    if (volume > 0) {
      videoActionData.add(
        ActionData(
            label: 'Volume mute',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.volume_mute)),
      );
    }
    if (volume > 0) {
      videoActionData.add(
        ActionData(
            label: 'Volume decrease',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.volume_down)),
      );
    }
    if (enableFullScreen) {
      videoActionData.add(
        ActionData(
            label: 'Zoom in',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.zoom_in_map)),
      );
    } else {
      videoActionData.add(
        ActionData(
            label: 'Zoom out',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.zoom_out_map)),
      );
    }
    videoActionData.add(
      ActionData(
          label: 'Close',
          // actionType: ActionType.inkwell,
          icon: const Icon(Icons.closed_caption_disabled)),
    );
    return videoActionData;
  }

  Future<dynamic> _showActionCard(BuildContext context) {
    return DialogUtil.popModalBottomSheet(context, builder: (context) {
      return Card(
          child: DataActionCard(
              onPressed: (int index, String label, {String? value}) {
                _onAction(context, index, label, value: value);
              },
              showLabel: true,
              showTooltip: true,
              crossAxisCount: 4,
              actions: _buildVideoActionData(),
              height: 120,
              width: 320,
              size: 20));
    });
  }

  ///单个视频窗口
  Widget _buildSingleVideoView(
      BuildContext context, double? height, double? width) {
    String name = widget.peerMediaStream.name ?? '';
    Widget mediaRenderView = P2pMediaRenderView(
        mediaStream: widget.peerMediaStream.mediaStream!, height: height, width: width);

    Widget singleVideoView = Builder(
      builder: (context) => InkWell(
        onTap: () async {
          setState(() {
            widget.peerMediaStreamController.currentPeerMediaStream = widget.peerMediaStream;
          });
        },
        onLongPress: () async {
          setState(() {
            widget.peerMediaStreamController.currentPeerMediaStream = widget.peerMediaStream;
          });
          await _showActionCard(context);
        },
        child: mediaRenderView,
      ),
    );
    var selected = false;
    if (widget.peerMediaStream.id != null &&
        widget.peerMediaStreamController.currentPeerMediaStream != null) {
      selected = widget.peerMediaStream.id ==
          widget.peerMediaStreamController.currentPeerMediaStream!.id;
    }
    return Container(
      decoration: selected
          ? BoxDecoration(border: Border.all(width: 1, color: myself.primary))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Stack(
        children: [
          singleVideoView,
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: CommonAutoSizeText(
                name,
                style: const TextStyle(
                    color: Colors.white, fontSize: AppFontSize.xsFontSize),
              )),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    var mediaStream = widget.peerMediaStream.mediaStream!;
    switch (name) {
      case 'Camera switch':
        await MediaStreamUtil.switchCamera(mediaStream);
        setState(() {});
        break;
      case 'Microphone switch':
        enableSpeaker = false;
        await MediaStreamUtil.switchSpeaker(mediaStream, enableSpeaker);
        setState(() {});
        break;
      case 'Speaker switch':
        enableSpeaker = true;
        await MediaStreamUtil.switchSpeaker(mediaStream, enableSpeaker);
        setState(() {});
        break;
      case 'Volume increase':
        volume = volume + 0.1;
        volume = volume > 1 ? 1 : volume;
        enableMute = false;
        setState(() {});
        await MediaStreamUtil.setVolume(mediaStream, volume);
        break;
      case 'Volume decrease':
        volume = volume - 0.1;
        volume = volume < 0 ? 0 : volume;
        enableMute = volume <= 0 ? true : false;
        setState(() {});
        await MediaStreamUtil.setVolume(mediaStream, volume);
        break;
      case 'Volume mute':
        enableMute = !enableMute;
        if (enableMute) {
          volume = 0;
        } else {
          volume = 1;
        }
        setState(() {
          MediaStreamUtil.setMute(mediaStream, enableMute);
        });
        break;
      case 'Zoom out':
        _popupDialog = _buildPopupDialog();
        Overlay.of(context).insert(_popupDialog);
        setState(() {
          enableFullScreen = true;
        });
        break;
      case 'Zoom in':
        _popupDialog.remove();
        setState(() {
          enableFullScreen = false;
        });
        break;
      case 'Close':
        await _close();
        break;
      default:
        break;
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _close() async {
    widget.onClosed(widget.peerMediaStream);
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleVideoView(context, widget.height, widget.width);
  }

  @override
  void dispose() {
    widget.peerMediaStreamController.unregisterPeerMediaStreamOperator(
        PeerMediaStreamOperator.selected.name, _updateSelected);
    widget.peerMediaStreamController.unregisterPeerMediaStreamOperator(
        PeerMediaStreamOperator.unselected.name, _updateSelected);
    super.dispose();
  }
}

// This a widget to implement the image scale animation, and background grey out effect.
class AnimatedContain extends StatefulWidget {
  const AnimatedContain({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<StatefulWidget> createState() => AnimatedContainState();
}

class AnimatedContainState extends State<AnimatedContain>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacityAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    scaleAnimation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutExpo);
    opacityAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutExpo));

    controller.addListener(() => setState(() {}));
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(opacityAnimation.value),
      child: Center(
        child: FadeTransition(
          opacity: scaleAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
