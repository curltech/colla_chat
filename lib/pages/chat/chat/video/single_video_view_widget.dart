import 'package:card_swiper/card_swiper.dart';
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

///单个小视频窗口，把相同的peerId的一组媒体流显示在一个滑动的窗口中swiper，
///长按出现更大的窗口，带有操作按钮
class SingleVideoViewWidget extends StatefulWidget {
  final PeerMediaStreamController peerMediaStreamController;
  final String peerId;
  final double? height;
  final double? width;

  const SingleVideoViewWidget({
    super.key,
    required this.peerMediaStreamController,
    required this.peerId,
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
  int index = 0;
  SwiperController swiperController = SwiperController();
  late List<PeerMediaStream> peerMediaStreams;

  @override
  initState() {
    super.initState();
    widget.peerMediaStreamController.addListener(_updateSelected);
    peerMediaStreams = _sortedPeerMediaStreams();
    if (peerMediaStreams.isNotEmpty) {
      volume.value = peerMediaStreams.first.getVolume() ?? 1;
      enableMute.value = peerMediaStreams.first.isMuted() ?? false;
    }
  }

  List<PeerMediaStream> _sortedPeerMediaStreams() {
    List<PeerMediaStream> peerMediaStreams =
        widget.peerMediaStreamController.getPeerMediaStreams(widget.peerId);
    List<PeerMediaStream> sortedPeerMediaStreams = [];
    for (PeerMediaStream peerMediaStream in peerMediaStreams) {
      if (peerMediaStream.mediaStream != null ||
          peerMediaStream.videoTrack != null) {
        sortedPeerMediaStreams.insert(0, peerMediaStream);
      } else {
        sortedPeerMediaStreams.add(peerMediaStream);
      }
    }

    return sortedPeerMediaStreams;
  }

  Future<void> _updateSelected() async {
    String? currentPeerId = widget.peerMediaStreamController.currentPeerId;
    if (this.peerMediaStreams.isNotEmpty) {
      String? peerId = this.peerMediaStreams.first.platformParticipant?.peerId;
      if (peerId != null && currentPeerId != null && peerId == currentPeerId) {
        setState(() {});
      }
    }
    List<PeerMediaStream> peerMediaStreams = _sortedPeerMediaStreams();
    if (peerMediaStreams.length != this.peerMediaStreams.length) {
      setState(() {
        this.peerMediaStreams = peerMediaStreams;
      });
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
    Widget mediaRenderView = Center(
        child: CommonAutoSizeText(AppLocalizations.t('No media stream')));
    if (peerMediaStreams.isEmpty) {
      return mediaRenderView;
    }
    var height = MediaQuery.sizeOf(context).height;
    var width = MediaQuery.sizeOf(context).width;
    mediaRenderView = PeerMediaRenderView(
        peerMediaStream: peerMediaStreams[index], height: height, width: width);
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
    if (peerMediaStreams.isEmpty) {
      return [];
    }
    PeerMediaStream peerMediaStream;
    if (peerMediaStreams.length == 1) {
      peerMediaStream = peerMediaStreams.first;
    } else if (index < peerMediaStreams.length) {
      peerMediaStream = peerMediaStreams[index];
    } else {
      return [];
    }
    List<ActionData> videoActionData = [];
    if (platformParams.mobile) {
      if (peerMediaStream.local) {
        videoActionData.add(
          ActionData(
              label: 'Camera switch', icon: const Icon(Icons.cameraswitch)),
        );
      }
    }
    if (enableSpeaker.value) {
      videoActionData.add(
        ActionData(label: 'Handset switch', icon: const Icon(Icons.earbuds)),
      );
    } else {
      videoActionData.add(
        ActionData(
            label: 'Speaker switch', icon: const Icon(Icons.speaker_phone)),
      );
    }
    if (peerMediaStream.local) {
      if (enableMute.value) {
        videoActionData.add(
          ActionData(label: 'Microphone unmute', icon: const Icon(Icons.mic)),
        );
      } else {
        videoActionData.add(
          ActionData(label: 'Microphone mute', icon: const Icon(Icons.mic_off)),
        );
      }
    }
    if (volume.value > 0) {
      videoActionData.add(
        ActionData(label: 'Volume mute', icon: const Icon(Icons.volume_mute)),
      );
    }
    if (volume.value > 0) {
      videoActionData.add(
        ActionData(
            label: 'Volume decrease', icon: const Icon(Icons.volume_down)),
      );
    }
    videoActionData.add(
      ActionData(label: 'Volume increase', icon: const Icon(Icons.volume_up)),
    );
    if (platformParams.mobile) {
      videoActionData.add(
        ActionData(label: 'Zoom in', icon: const Icon(Icons.zoom_in_map)),
      );
      videoActionData.add(
        ActionData(label: 'Zoom out', icon: const Icon(Icons.zoom_out_map)),
      );
    }

    if (peerMediaStream.local) {
      videoActionData.add(
        ActionData(
            label: 'Close', icon: const Icon(Icons.closed_caption_disabled)),
      );
    }
    return videoActionData;
  }

  Future<dynamic> _showActionCard(BuildContext context) async {
    List<ActionData> actions = _buildVideoActionData();
    if (actions.isEmpty) {
      return null;
    }
    return DialogUtil.popModalBottomSheet(builder: (context) {
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
    Widget mediaRenderView = Center(
        child: CommonAutoSizeText(AppLocalizations.t('No media stream')));
    if (peerMediaStreams.isEmpty) {
      return mediaRenderView;
    }
    String name = peerMediaStreams.first.platformParticipant?.name ?? '';
    if (peerMediaStreams.length == 1) {
      index = 0;
      mediaRenderView = PeerMediaRenderView(
          peerMediaStream: peerMediaStreams.first,
          height: height,
          width: width);
    } else {
      List<Widget> views = [];
      for (PeerMediaStream peerMediaStream in peerMediaStreams) {
        mediaRenderView = PeerMediaRenderView(
            peerMediaStream: peerMediaStream, height: height, width: width);
        views.add(mediaRenderView);
      }
      mediaRenderView = Swiper(
        controller: swiperController,
        itemCount: views.length,
        itemBuilder: (BuildContext context, int index) {
          return views[index];
        },
        onIndexChanged: (int index) {
          this.index = index;
        },
        index: index,
      );
    }
    Widget singleVideoView = Builder(
      builder: (context) => InkWell(
        onTap: () async {
          widget.peerMediaStreamController.currentPeerId =
              peerMediaStreams.first.platformParticipant?.peerId;
        },
        onLongPress: () async {
          widget.peerMediaStreamController.currentPeerId =
              peerMediaStreams.first.platformParticipant?.peerId;
          await _showActionCard(context);
        },
        child: mediaRenderView,
      ),
    );
    bool selected = false;
    if (peerMediaStreams.first.platformParticipant?.peerId != null &&
        widget.peerMediaStreamController.currentPeerId != null) {
      selected = peerMediaStreams.first.platformParticipant?.peerId ==
          widget.peerMediaStreamController.currentPeerId;
    }
    List<Widget> children = [
      singleVideoView,
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CommonAutoSizeText(
              name,
              style: const TextStyle(
                  color: Colors.white, fontSize: AppFontSize.xsFontSize),
            ),
            ValueListenableBuilder(
                valueListenable: volume,
                builder: (BuildContext context, double volume, Widget? child) {
                  return CommonAutoSizeText(
                    '$volume',
                    style: const TextStyle(
                        color: Colors.white, fontSize: AppFontSize.xsFontSize),
                  );
                }),
            ValueListenableBuilder(
                valueListenable: enableMute,
                builder:
                    (BuildContext context, bool enableMute, Widget? child) {
                  return Icon(
                    enableMute ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  );
                }),
          ])),
    ];
    if (peerMediaStreams.length > 1) {
      children.add(Align(
          alignment: Alignment.topRight,
          child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: IconButton(
                onPressed: () {
                  swiperController.next();
                },
                icon: const Icon(
                    size: 36.0,
                    color: Colors.white,
                    Icons.navigate_next_outlined),
              ))));
    }
    return Container(
      decoration: selected
          ? BoxDecoration(border: Border.all(width: 1, color: myself.primary))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Stack(
        children: children,
      ),
    );
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    PeerMediaStream peerMediaStream;
    if (peerMediaStreams.isEmpty) {
      return;
    } else if (peerMediaStreams.length == 1) {
      peerMediaStream = peerMediaStreams.first;
    } else if (this.index < peerMediaStreams.length) {
      peerMediaStream = peerMediaStreams[this.index];
    } else {
      peerMediaStream = peerMediaStreams.first;
    }
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
        if (peerMediaStreams.length > 1) {
          swiperController.next();
        }
        await widget.peerMediaStreamController.close(peerMediaStream);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    peerMediaStreams = widget.peerMediaStreamController
        .getPeerMediaStreams(widget.peerId)
        .toList();
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
