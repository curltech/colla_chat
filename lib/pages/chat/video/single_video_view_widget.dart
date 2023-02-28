import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';

///单个小视频窗口，显示一个视频流的PeerVideoRender，长按出现更大的窗口，带有操作按钮
class SingleVideoViewWidget extends StatefulWidget {
  final VideoRenderController videoRenderController;
  final Conference? conference;
  final PeerVideoRender render;
  final double? height;
  final double? width;

  const SingleVideoViewWidget({
    Key? key,
    required this.videoRenderController,
    this.conference,
    required this.render,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  State createState() => _SingleVideoViewWidgetState();
}

class _SingleVideoViewWidgetState extends State<SingleVideoViewWidget> {
  bool actionVisible = false;
  bool enableFullScreen = false;
  bool enableMute = false;
  bool enableSpeaker = false;
  bool enableTorch = false;
  double volume = 1;

  late OverlayEntry _popupDialog;

  @override
  initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  OverlayEntry _buildPopupDialog() {
    return OverlayEntry(
      builder: (context) => AnimatedContain(
        child: _buildPopupVideoView(),
      ),
    );
  }

  Widget _buildAppBar() {
    return _buildActionCard(context);
  }

  Widget _buildPopupVideoView() {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    Widget videoView = Stack(children: [
      widget.render.createVideoView(height: height, width: width),
      _buildAppBar(),
    ]);

    return videoView;
  }

  List<ActionData> _buildVideoActionData() {
    List<ActionData> videoActionData = [];
    if (widget.videoRenderController.currentVideoRender != null) {
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
          icon: const Icon(Icons.close)),
    );
    return videoActionData;
  }

  Widget _buildActionCard(BuildContext context) {
    return Visibility(
        visible: actionVisible,
        child: Center(
            child: Card(
                child: DataActionCard(
                    onPressed: (int index, String label, {String? value}) {
                      _onAction(context, index, label, value: value);
                    },
                    showLabel: false,
                    showTooltip: false,
                    crossAxisCount: 4,
                    actions: _buildVideoActionData(),
                    // height: 120,
                    //width: 320,
                    size: 20))));
  }

  ///单个视频窗口
  Widget _buildSingleVideoView(
      BuildContext context, double? height, double? width) {
    String name = widget.render.name ?? '';
    Widget actionWidget = _buildActionCard(context);
    Widget videoView =
        widget.render.createVideoView(height: height, width: width);
    Widget singleVideoView = Builder(
      builder: (context) => InkWell(
        onTap: () {
          setState(() {
            actionVisible = !actionVisible;
            widget.videoRenderController.currentVideoRender = widget.render;
          });
        },
        child: videoView,
      ),
    );
    var selected = false;
    if (widget.render.id != null &&
        widget.videoRenderController.currentVideoRender != null) {
      selected = widget.render.id ==
          widget.videoRenderController.currentVideoRender!.id;
    }
    var primary = myself.primary;
    return Container(
      decoration: selected
          ? BoxDecoration(border: Border.all(width: 1, color: Colors.yellow))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Stack(
        children: [
          singleVideoView,
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )),
          actionWidget,
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    switch (name) {
      case 'Camera switch':
        await widget.render.switchCamera();
        setState(() {});
        break;
      case 'Microphone switch':
        enableSpeaker = false;
        await widget.render.switchSpeaker(enableSpeaker);
        setState(() {});
        break;
      case 'Speaker switch':
        enableSpeaker = true;
        await widget.render.switchSpeaker(enableSpeaker);
        setState(() {});
        break;
      case 'Volume increase':
        volume = volume + 0.1;
        volume = volume > 1 ? 1 : volume;
        enableMute = false;
        setState(() {});
        await widget.render.setVolume(volume);
        break;
      case 'Volume decrease':
        volume = volume - 0.1;
        volume = volume < 0 ? 0 : volume;
        enableMute = volume <= 0 ? true : false;
        setState(() {});
        await widget.render.setVolume(volume);
        break;
      case 'Volume mute':
        enableMute = !enableMute;
        if (enableMute) {
          volume = 0;
        } else {
          volume = 1;
        }
        setState(() {
          widget.render.setMute(enableMute);
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
        if (widget.conference != null) {
          String conferenceId = widget.conference!.conferenceId;
          await videoConferenceRenderPool
              .removeVideoRender(conferenceId, [widget.render]);
        }
        await widget.videoRenderController.close(widget.render.id!);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleVideoView(context, widget.height, widget.width);
  }

  @override
  void dispose() {
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
