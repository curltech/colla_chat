import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_render_view.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

///单个小视频窗口，显示一个视频流的PeerpeerMediaStream，长按出现更大的窗口，带有操作按钮
class SingleVideoViewWidget extends StatefulWidget {
  final PeerMediaStreamController peerMediaStreamController;
  final PeerMediaStream peerMediaStream;
  final double? height;
  final double? width;
  final Function(PeerMediaStream peerMediaStream) onClosed;

  const SingleVideoViewWidget({
    super.key,
    required this.peerMediaStreamController,
    required this.onClosed,
    required this.peerMediaStream,
    this.height,
    this.width,
  });

  @override
  State createState() => _SingleVideoViewWidgetState();
}

class _SingleVideoViewWidgetState extends State<SingleVideoViewWidget> {
  bool enableFullScreen = false;
  ValueNotifier<bool> enableMute = ValueNotifier<bool>(false);
  ValueNotifier<bool> enableSpeaker = ValueNotifier<bool>(false);
  ValueNotifier<bool> enableTorch = ValueNotifier<bool>(false);
  ValueNotifier<double> volume = ValueNotifier<double>(1);
  ValueNotifier<double> zoomLevel = ValueNotifier<double>(1);

  late OverlayEntry _popupDialog;

  @override
  initState() {
    super.initState();
    widget.peerMediaStreamController.addListener(_updateSelected);
    volume.value = widget.peerMediaStream.getVolume() ?? 1;
    enableMute.value = widget.peerMediaStream.isMuted() ?? false;
  }

  Future<void> _updateSelected() async {
    PeerMediaStream? peerMediaStream =
        widget.peerMediaStreamController.currentPeerMediaStream;
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
    Widget mediaRenderView = PeerMediaRenderView(
        peerMediaStream: widget.peerMediaStream, height: height, width: width);
    Widget singleVideoView = Builder(
      builder: (context) => InkWell(
        onLongPress: () async {
          await _showActionCard(context);
        },
        onDoubleTap: () {
          _popupDialog.remove();
          setState(() {
            enableFullScreen = false;
          });
        },
        child: mediaRenderView,
      ),
    );

    return singleVideoView;
  }

  List<ActionData> _buildVideoActionData() {
    List<ActionData> videoActionData = [];
    Participant<TrackPublication<Track>>? participant =
        widget.peerMediaStream.participant;
    if (platformParams.mobile) {
      if (widget.peerMediaStream.local) {
        videoActionData.add(
          ActionData(
              label: 'Camera switch',
              //actionType: ActionType.inkwell,
              icon: const Icon(Icons.cameraswitch)),
        );
      }
    }
    if (enableSpeaker.value) {
      videoActionData.add(
        ActionData(
            label: 'Handset switch',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.earbuds)),
      );
    } else {
      videoActionData.add(
        ActionData(
            label: 'Speaker switch',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.speaker_phone)),
      );
    }
    if (widget.peerMediaStream.local) {
      if (enableMute.value) {
        videoActionData.add(
          ActionData(
              label: 'Microphone unmute',
              // actionType: ActionType.inkwell,
              icon: const Icon(Icons.mic)),
        );
      } else {
        videoActionData.add(
          ActionData(
              label: 'Microphone mute',
              // actionType: ActionType.inkwell,
              icon: const Icon(Icons.mic_off)),
        );
      }
    }
    if (volume.value > 0) {
      videoActionData.add(
        ActionData(
            label: 'Volume mute',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.volume_mute)),
      );
    }
    if (volume.value > 0) {
      videoActionData.add(
        ActionData(
            label: 'Volume decrease',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.volume_down)),
      );
    }
    videoActionData.add(
      ActionData(
          label: 'Volume increase',
          // actionType: ActionType.inkwell,
          icon: const Icon(Icons.volume_up)),
    );
    if (platformParams.mobile) {
      videoActionData.add(
        ActionData(
            label: 'Zoom in',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.zoom_in_map)),
      );
      videoActionData.add(
        ActionData(
            label: 'Zoom out',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.zoom_out_map)),
      );
    }

    if (widget.peerMediaStream.local) {
      videoActionData.add(
        ActionData(
            label: 'Close',
            // actionType: ActionType.inkwell,
            icon: const Icon(Icons.closed_caption_disabled)),
      );
    }
    return videoActionData;
  }

  Future<dynamic> _showActionCard(BuildContext context) {
    return DialogUtil.popModalBottomSheet(context, builder: (context) {
      List<ActionData> actions = _buildVideoActionData();
      int level = (actions.length / 3).ceil();
      double height = 100.0 * level;
      return Card(
          child: DataActionCard(
              onPressed: (int index, String label, {String? value}) {
                _onAction(context, index, label, value: value);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              showLabel: true,
              showTooltip: true,
              crossAxisCount: 3,
              actions: actions,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              height: height,
              width: appDataProvider.secondaryBodyWidth,
              iconSize: 30));
    });
  }

  ///单个视频窗口
  Widget _buildSingleVideoView(
      BuildContext context, double? height, double? width) {
    String name = widget.peerMediaStream.platformParticipant?.name ?? '';
    String streamId = widget.peerMediaStream.id ?? '';
    String ownerTag = widget.peerMediaStream.ownerTag ?? '';
    bool video = widget.peerMediaStream.video;
    Widget mediaRenderView =
        Center(child: CommonAutoSizeText(AppLocalizations.t('No stream')));
    var peerMediaStream = widget.peerMediaStream;
    mediaRenderView = PeerMediaRenderView(
        peerMediaStream: peerMediaStream, height: height, width: width);

    Widget singleVideoView = Builder(
      builder: (context) => InkWell(
        onTap: () async {
          setState(() {
            widget.peerMediaStreamController.currentPeerMediaStream =
                widget.peerMediaStream;
          });
        },
        onLongPress: () async {
          setState(() {
            widget.peerMediaStreamController.currentPeerMediaStream =
                widget.peerMediaStream;
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonAutoSizeText(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.xsFontSize),
                    ),
                    // CommonAutoSizeText(
                    //   streamId,
                    //   style: const TextStyle(
                    //       color: Colors.white,
                    //       fontSize: AppFontSize.xsFontSize),
                    // ),
                    // CommonAutoSizeText(
                    //   ownerTag,
                    //   style: const TextStyle(
                    //       color: Colors.white,
                    //       fontSize: AppFontSize.xsFontSize),
                    // ),
                    ValueListenableBuilder(
                        valueListenable: volume,
                        builder: (BuildContext context, double volume,
                            Widget? child) {
                          return CommonAutoSizeText(
                            '$volume',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppFontSize.xsFontSize),
                          );
                        }),
                    ValueListenableBuilder(
                        valueListenable: enableMute,
                        builder: (BuildContext context, bool enableMute,
                            Widget? child) {
                          return Icon(
                            enableMute ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          );
                        }),
                  ])),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    PeerMediaStream peerMediaStream = widget.peerMediaStream;
    switch (name) {
      case 'Camera switch':
        await peerMediaStream.switchCamera();
        break;
      case 'Handset switch':
        enableSpeaker.value = false;
        await peerMediaStream.switchSpeaker(enableSpeaker.value);
        break;
      case 'Speaker switch':
        enableSpeaker.value = true;
        await peerMediaStream.switchSpeaker(enableSpeaker.value);
        break;
      case 'Microphone unmute':
        enableMute.value = false;
        await peerMediaStream.setMicrophoneMute(enableMute.value);
        break;
      case 'Microphone mute':
        enableMute.value = true;
        await peerMediaStream.setMicrophoneMute(enableMute.value);
        break;
      case 'Volume increase':
        double val = volume.value + 0.1;
        val = val > 1 ? 1 : val;
        volume.value = val;
        await peerMediaStream.setVolume(val);
        break;
      case 'Volume decrease':
        double val = volume.value - 0.1;
        val = val < 0 ? 0 : val;
        volume.value = val;
        await peerMediaStream.setVolume(val);
        break;
      case 'Volume mute':
        double val = volume.value;
        if (val == 0) {
          volume.value = 1;
        } else {
          volume.value = 0;
        }
        peerMediaStream.setVolume(volume.value);
        break;
      case 'Zoom out':
        double val = zoomLevel.value + 0.1;
        //val = val > 1 ? 1 : val;
        zoomLevel.value = val;
        await peerMediaStream.setZoom(val);
        break;
      case 'Zoom in':
        double val = zoomLevel.value - 0.1;
        //val = val < 0 ? 0 : val;
        zoomLevel.value = val;
        await peerMediaStream.setZoom(val);
        break;
      case 'Close':
        await _close();
        break;
      default:
        break;
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
    widget.peerMediaStreamController.removeListener(_updateSelected);
    super.dispose();
  }
}

// This a widget to implement the image scale animation, and background grey out effect.
class AnimatedContain extends StatefulWidget {
  const AnimatedContain({super.key, required this.child});

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
