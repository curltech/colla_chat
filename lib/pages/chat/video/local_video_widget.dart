import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group_linkman_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/video/video_view_card.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///视频通话的流程，适用单个通话和群
///1.发起方在本地通话窗口发起视频通话请求（缺省会打开本地的视频或者音频，但不会打开屏幕共享），
///实际是先打开本地流（还没有加入连接中，重新协商），
///然后一个视频通话的邀请消息发送出去，邀请消息的编号也是房间号，以后通过消息编号可以重新加入
///2.接收方接收视频通话请求，屏幕顶部激活拨入对话框；
///3.接收方选择接受或者拒绝，无论接受或者拒绝，先发送回执消息，关闭对话框，
///如果是接受，打开本地视频或者音频，并加入本地连接，打开本地通话窗口，打开远程通话窗口，等待远程视频流到来，开始通话
///4.接收方如果选择拒绝，以后可以通过点击视频通话请求消息重新进入本地通话窗口，然后再次加入视频，
///5.发起方收到回执，如果是是接受回执，关闭本地通话窗口，本地流加入连接中，重新协商，打开远程通话窗口，
///等待协商结束，远程视频流到来，开始通话
///6.发起方收到回执，如果是拒绝回执，关闭本地通话窗口和本地流，回到文本通话窗口
///7.任何方主动终止请求，发起视频通话终止请求，执行挂断操作，设置挂断标志，关闭本地流和远程流
///8.任何方接受到视频通话终止请求消息，执行挂断操作，设置挂断标志，关闭本地流和远程流，发起重新协商

///本地视频通话显示和拨出的窗口，显示多个本地视频，音频和屏幕共享的小视频窗口
///各种功能按钮，可以切换视频和音频，添加屏幕共享视频，此时需要发起重新协商
class LocalVideoWidget extends StatefulWidget {
  const LocalVideoWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LocalVideoWidgetState();
  }
}

class _LocalVideoWidgetState extends State<LocalVideoWidget> {
  ValueNotifier<VideoChatMessageController?> videoChatMessageController =
      ValueNotifier<VideoChatMessageController?>(
          videoConferenceRenderPool.videoChatMessageController);

  ChatSummary chatSummary = chatMessageController.chatSummary!;

  //控制面板的可见性，包括视频功能按钮和呼叫按钮
  ValueNotifier<bool> controlPanelVisible = ValueNotifier<bool>(true);

  //视频通话窗口的可见性
  ValueNotifier<int> videoViewCount = ValueNotifier<int>(0);

  //视频功能按钮对应的数据
  ValueNotifier<List<ActionData>> actionData =
      ValueNotifier<List<ActionData>>([]);

  //呼叫状态
  ValueNotifier<VideoChatStatus> videoChatStatus =
      ValueNotifier<VideoChatStatus>(VideoChatStatus.end);

  //Speaker状态
  ValueNotifier<bool> speakerStatus = ValueNotifier<bool>(false);

  //控制面板可见性的计时器
  Timer? _hideControlPanelTimer;

  //呼叫时间的计时器，如果是在单聊的场景下，对方在时间内未有回执，则自动关闭
  Timer? _linkmanCallTimer;

  BlueFireAudioPlayer audioPlayer = BlueFireAudioPlayer();

  //JustAudioPlayer audioPlayer = JustAudioPlayer();

  @override
  void initState() {
    super.initState();
    // 本地视频可能在其他地方关闭，所有需要注册关闭事件
    localVideoRenderController.registerVideoRenderOperator(
        VideoRenderOperator.remove.name, _updateVideoRender);
    videoConferenceRenderPool.addListener(_updateVideoChatMessageController);
    _updateVideoChatMessageController();
    _update();
  }

  _updateVideoChatMessageController() {
    var videoChatMessageController = this.videoChatMessageController.value;
    if (videoChatMessageController != null) {
      videoChatMessageController.removeListener(_updateVideoChatStatus);
      videoChatMessageController.unregisterReceiver(
          ChatMessageSubType.chatReceipt.name, _receivedChatReceipt);
    }
    videoChatMessageController =
        videoConferenceRenderPool.videoChatMessageController;
    if (videoChatMessageController != null) {
      videoChatMessageController.addListener(_updateVideoChatStatus);
      videoChatStatus.value = videoChatMessageController.status;
      videoChatMessageController.registerReceiver(
          ChatMessageSubType.chatReceipt.name, _receivedChatReceipt);
    } else {
      videoChatStatus.value = VideoChatStatus.end;
    }
    this.videoChatMessageController.value = videoChatMessageController;
    _update();
  }

  _updateVideoChatStatus() {
    var videoChatMessageController = this.videoChatMessageController.value;
    if (videoChatMessageController != null) {
      videoChatStatus.value = videoChatMessageController.status;
      if (mounted) {
        DialogUtil.info(context,
            content: AppLocalizations.t('Video chat status:') +
                AppLocalizations.t(videoChatStatus.value.name));
      }
    }
  }

  _play() {
    audioPlayer.setLoopMode(true);
    audioPlayer.play('assets/medias/call.mp3');
  }

  _stop() async {
    await audioPlayer.release();
    audioPlayer.setLoopMode(false);
    audioPlayer.play('assets/medias/close.mp3');
  }

  ///收到回执，如果是拒绝，则stop呼叫
  _receivedChatReceipt(ChatMessage chatReceipt) {
    if (chatReceipt.receiptType == MessageReceiptType.rejected.name) {
      _stop();
    }
  }

  Future<void> _updateVideoRender(PeerVideoRender? peerVideoRender) async {
    _update();
  }

  ///调整界面的显示
  Future<void> _update() async {
    List<ActionData> actionData = [];
    if (localVideoRenderController.mainVideoRender == null ||
        !localVideoRenderController.video) {
      actionData.add(
        ActionData(
            label: 'Video',
            tooltip: 'Open local video',
            icon: const Icon(Icons.video_call, color: Colors.white)),
      );
    }
    if (localVideoRenderController.mainVideoRender == null ||
        localVideoRenderController.video) {
      actionData.add(
        ActionData(
          label: 'Audio',
          tooltip: 'Open local audio',
          icon: const Icon(Icons.multitrack_audio, color: Colors.white),
        ),
      );
    }
    if (localVideoRenderController.mainVideoRender != null) {
      actionData.add(
        ActionData(
            label: 'Screen share',
            tooltip: 'Open screen share',
            icon: const Icon(Icons.screen_share, color: Colors.white)),
      );
    }
    // actionData.add(
    //   ActionData(
    //       label: 'Media play',
    //       tooltip: 'Open media play',
    //       icon: const Icon(Icons.video_file, color: Colors.white)),
    // );
    if (localVideoRenderController.videoRenders.isNotEmpty) {
      actionData.add(
        ActionData(
            label: 'Close',
            tooltip: 'Close all video',
            icon:
                const Icon(Icons.closed_caption_disabled, color: Colors.white)),
      );
    } else {
      controlPanelVisible.value = true;
    }
    this.actionData.value = actionData;
    videoViewCount.value = localVideoRenderController.videoRenders.length;
  }

  ///创建本地的Video render，支持视频和音频的切换，设置当前videoChatRender，激活create。add和remove监听事件
  Future<PeerVideoRender?> _openVideoMedia({bool video = true}) async {
    var videoChatMessageController = this.videoChatMessageController.value;

    ///本地视频不存在，可以直接创建，并发送视频邀请消息，否则根据情况觉得是否音视频切换
    PeerVideoRender? videoRender = localVideoRenderController.mainVideoRender;
    if (videoRender == null) {
      if (video) {
        videoRender = await localVideoRenderController.createVideoMediaRender();
      } else {
        videoRender = await localVideoRenderController.createAudioMediaRender();
      }
      await videoChatMessageController?.addLocalVideoRender(videoRender);
      _update();
    } else {
      if (video) {
        if (!localVideoRenderController.video) {
          await videoChatMessageController?.removeVideoRender(videoRender);
          await localVideoRenderController.close(videoRender);
          videoRender =
              await localVideoRenderController.createVideoMediaRender();
          await videoChatMessageController?.addLocalVideoRender(videoRender);
          _update();
        }
      } else {
        if (localVideoRenderController.video) {
          await videoChatMessageController?.removeVideoRender(videoRender);
          await localVideoRenderController.close(videoRender);
          videoRender =
              await localVideoRenderController.createAudioMediaRender();
          await videoChatMessageController?.addLocalVideoRender(videoRender);
          _update();
        }
      }
    }
    return videoRender;
  }

  Future<PeerVideoRender?> _openDisplayMedia() async {
    var videoChatMessageController = this.videoChatMessageController.value;
    final source = await DialogUtil.show<DesktopCapturerSource>(
      context: context,
      builder: (context) => Dialog(child: ScreenSelectDialog()),
    );
    if (source != null) {
      PeerVideoRender videoRender = await localVideoRenderController
          .createDisplayMediaRender(selectedSource: source);
      await videoChatMessageController?.addLocalVideoRender(videoRender);
      _update();

      return videoRender;
    }
    return null;
  }

  Future<PeerVideoRender?> _openMediaStream(MediaStream stream) async {
    var videoChatMessageController = this.videoChatMessageController.value;
    ChatMessage? chatMessage = videoChatMessageController?.chatMessage;
    if (chatMessage == null) {
      DialogUtil.error(context, content: AppLocalizations.t('No conference'));
      return null;
    }
    PeerVideoRender? videoRender =
        await localVideoRenderController.createMediaStreamRender(stream);
    await videoChatMessageController?.addLocalVideoRender(videoRender);
    _update();

    return videoRender;
  }

  ///选择会议参加人的界面，返回会议参加人
  ///在会议模式和群模式下，弹出对话框选择参加人
  ///在对话模式下直接加入对方
  Future<List<String>> _selectParticipants() async {
    List<String> participants = [];
    var partyType = chatSummary.partyType!;
    if (partyType == PartyType.conference.name) {
      List<String> selected = <String>[];
      await DialogUtil.show(
          context: context,
          // title: AppBarWidget.buildTitleBar(
          //     title: CommonAutoSizeText(AppLocalizations.t('Select one linkman'))),
          builder: (BuildContext context) {
            return LinkmanGroupSearchWidget(
                onSelected: (List<String>? peerIds) async {
                  if (peerIds != null) {
                    for (var peerId in peerIds) {
                      if (!participants.contains(peerId)) {
                        participants.add(peerId);
                      }
                    }
                  }
                  Navigator.pop(context, participants);
                },
                selected: selected,
                includeGroup: false,
                selectType: SelectType.chipMultiSelect);
          });
    } else if (partyType == PartyType.group.name) {
      var groupId = chatSummary.peerId;
      if (groupId == null) {
        return participants;
      }
      if (mounted) {
        await DialogUtil.show(
            context: context,
            builder: (BuildContext context) {
              return GroupLinkmanWidget(
                onSelected: (List<String> peerIds) {
                  for (var peerId in peerIds) {
                    if (!participants.contains(peerId)) {
                      participants.add(peerId);
                    }
                  }
                  Navigator.pop(context, participants);
                },
                selected: const <String>[],
                groupId: groupId,
              );
            });
      }
    } else if (partyType == PartyType.linkman.name) {
      var peerId = chatSummary.peerId;
      if (peerId == null) {
        return participants;
      }
      if (!participants.contains(peerId)) {
        participants.add(peerId);
      }
    }

    return participants;
  }

  ///呼叫或者加入会议，如果当前没有选择会议邀请消息（linkman或者group模式下），则呼叫
  ///呼叫需要创建新的视频会议conference，linkman模式下是临时conference，不存储，group模式下存储
  ///发出会议邀请消息
  ///加入会议是在当前选择了会议邀请消息后的操作，需要创建本地视频（如果不存在）
  bool _checkWebrtcStatus() {
    //检查webrtc的状态
    var name = chatSummary.name;
    var partyType = chatSummary.partyType;
    var peerId = chatSummary.peerId;
    if (partyType == PartyType.linkman.name && peerId != null) {
      var status = peerConnectionPool.status(peerId);
      if (status != PeerConnectionStatus.connected) {
        DialogUtil.error(context,
            content:
                '$name ${AppLocalizations.t('has no webrtc connected peerConnection')}');
        return false;
      }
    }
    return true;
  }

  ///选择会议参与者，发送会议邀请消息，然后将新会议加入会议池，成为当前会议
  Future<void> _invite() async {
    var status = _checkWebrtcStatus();
    if (!status) {
      return;
    }
    List<String> participants = await _selectParticipants();
    if (!participants.contains(myself.peerId!)) {
      participants.add(myself.peerId!);
    }
    if (participants.length < 2) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Please select participants'));
      }
      return;
    }
    if (this.videoChatMessageController.value != null) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Current conference is exist'));
      }
      return;
    }
    var videoChatMessageController = VideoChatMessageController();
    this.videoChatMessageController.value = videoChatMessageController;
    await videoChatMessageController.setChatSummary(chatSummary);

    ///根据本地视频决定音视频选项，如果没有则认为是音频
    PeerVideoRender? mainVideoRender =
        localVideoRenderController.mainVideoRender;
    bool video = false;
    if (mainVideoRender != null) {
      video = mainVideoRender.video;
    }
    await videoChatMessageController.buildConference(
        video: video, participants: participants);
    Conference? conference = videoChatMessageController.conference;
    if (conference == null) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Create conference failure'));
      }
    }

    await videoChatMessageController.openLocalMainVideoRender();
    //发送会议邀请消息
    await videoChatMessageController.inviteWithChatSummary();
    ChatMessage? chatMessage = videoChatMessageController.chatMessage;
    if (chatMessage != null) {
      if (mounted) {
        DialogUtil.info(context,
            content:
                '${AppLocalizations.t('Send videoChat chatMessage')} ${chatMessage.messageId}');
      }
      _play();
      //延时60秒后自动挂断
      Future.delayed(const Duration(seconds: 60)).then((value) {
        //时间到了后，如果还是呼叫状态，则修改状态为结束
        if (videoChatMessageController.status == VideoChatStatus.calling) {
          _stop();
          videoChatMessageController.status = VideoChatStatus.end;
        }
      });
    } else {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Send videoChat chatMessage failure'));
      }
    }
    _update();
  }

  ///加入当前会议，即开始视频会议
  Future<void> _join() async {
    var status = _checkWebrtcStatus();
    if (!status) {
      return;
    }
    var videoChatMessageController = this.videoChatMessageController.value;
    if (videoChatMessageController == null) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('No video chat message controller'));
      }
      return;
    }
    ChatMessage? chatMessage = videoChatMessageController.chatMessage;
    if (chatMessage == null) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('No video chat message'));
      }
      return;
    }
    Conference? conference = videoChatMessageController.conference;
    if (conference == null) {
      if (mounted) {
        DialogUtil.error(context, content: AppLocalizations.t('No conference'));
      }
      return;
    }
    await videoChatMessageController.openLocalMainVideoRender();
    await videoChatMessageController.join();
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Join conference:') + conference.name);
    }
    _update();
  }

  ///移除本地所有的视频，这时候还能看远程的视频
  _close() async {
    var videoRenders = localVideoRenderController.videoRenders.values.toList();
    var videoChatMessageController = this.videoChatMessageController.value;
    Conference? conference = videoChatMessageController?.conference;
    if (conference != null) {
      await videoConferenceRenderPool.removeVideoRender(
          conference.conferenceId, videoRenders);
    }
    await localVideoRenderController.exit();
    _update();
  }

  _hangup() async {
    _stop();
    var videoChatMessageController = this.videoChatMessageController.value;
    videoChatMessageController!.status = VideoChatStatus.end;
  }

  ///如果正在呼叫calling，停止呼叫，关闭所有的本地视频，呼叫状态改为结束
  ///如果正在通话chatting，挂断视频通话，关闭所有的本地视频和远程视频，呼叫状态改为结束
  ///结束会议，这时候本地和远程的视频都应该被关闭
  _exit() async {
    var videoChatMessageController = this.videoChatMessageController.value;
    var status = videoChatMessageController?.status;
    if (status == VideoChatStatus.chatting) {
      await _close();
      Conference? conference = videoChatMessageController!.conference;
      if (conference != null) {
        await videoChatMessageController.exit();
      }
    }
    videoChatMessageController?.status = VideoChatStatus.end;
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Video':
        await _openVideoMedia();
        break;
      case 'Audio':
        await _openVideoMedia(video: false);
        break;
      case 'Screen share':
        await _openDisplayMedia();
        break;
      case 'Media play':
        //await _openMediaStream(stream);
        break;
      case 'Close':
        await _close();
        break;
      default:
        break;
    }
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 80;
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: ValueListenableBuilder<List<ActionData>>(
          valueListenable: actionData,
          builder: (context, value, child) {
            return DataActionCard(
              actions: value,
              height: height,
              //width: 320,
              onPressed: _onAction,
              crossAxisCount: 4,
              labelColor: Colors.white,
            );
          }),
    );
  }

  ///切换显示按钮面板
  void _toggleActionCardVisible() {
    bool visible = localVideoRenderController.videoRenders.isEmpty;
    if (visible) {
      controlPanelVisible.value = true;
    } else {
      if (_hideControlPanelTimer != null) {
        _hideControlPanelTimer?.cancel();
        controlPanelVisible.value = false;
        _hideControlPanelTimer = null;
      } else {
        controlPanelVisible.value = true;
        _hideControlPanelTimer?.cancel();
        _hideControlPanelTimer = Timer(const Duration(seconds: 15), () {
          if (!mounted) return;
          controlPanelVisible.value = false;
          _hideControlPanelTimer = null;
        });
      }
    }
  }

  ///控制面板
  Widget _buildControlPanel(BuildContext context) {
    return Column(children: [
      const Spacer(),
      ValueListenableBuilder<bool>(
          valueListenable: controlPanelVisible,
          builder: (context, value, child) {
            return Visibility(
                visible: controlPanelVisible.value,
                child: Column(children: [
                  _buildActionCard(context),
                  _buildCallButton(),
                ]));
          }),
    ]);
  }

  Widget _buildSpeakerSwitchButton(BuildContext context) {
    Widget button = ValueListenableBuilder<bool>(
        valueListenable: speakerStatus,
        builder: (BuildContext context, bool status, Widget? child) {
          return CircleTextButton(
            label: status ? 'Speaker on' : 'Speaker off',
            onPressed: () async {
              speakerStatus.value = !speakerStatus.value;
              await audioPlayer.setAudioContext(
                  forceSpeaker: speakerStatus.value);
            },
            backgroundColor: status ? Colors.black : Colors.white,
            child: Icon(
              status ? Icons.volume_up : Icons.volume_off,
              size: AppIconSize.mdSize,
              color: status ? Colors.white : Colors.black,
            ),
          );
        });

    return button;
  }

  ///创建呼叫按钮
  Widget _buildCallButton() {
    return ValueListenableBuilder<VideoChatStatus>(
        valueListenable: videoChatStatus,
        builder: (BuildContext context, VideoChatStatus value, Widget? child) {
          Widget buttonWidget;
          if (value == VideoChatStatus.calling ||
              value == VideoChatStatus.chatting) {
            String? label;
            String? tip;
            if (value == VideoChatStatus.calling) {
              label = 'Hangup';
              tip = 'Calling';
            } else if (value == VideoChatStatus.chatting) {
              label = 'Exit';
              tip = 'Chatting';
            }
            buttonWidget = CircleTextButton(
              label: label,
              tip: tip,
              onPressed: () {
                if (value == VideoChatStatus.calling) {
                  _hangup();
                } else if (value == VideoChatStatus.chatting) {
                  _exit();
                }
              },
              backgroundColor: Colors.red,
              child: const Icon(
                Icons.call_end,
                size: AppIconSize.mdSize,
                color: Colors.white,
              ),
            );
            if (value == VideoChatStatus.calling && platformParams.mobile) {
              buttonWidget =
                  ButtonBar(alignment: MainAxisAlignment.center, children: [
                buttonWidget,
                _buildSpeakerSwitchButton(context),
              ]);
            }
          } else if (value == VideoChatStatus.end) {
            String? label;
            String? tip;
            var videoChatMessageController =
                this.videoChatMessageController.value;
            Conference? conference = videoChatMessageController?.conference;
            if (conference == null) {
              label = 'Invite';
              tip = 'No conference';
            } else {
              label = 'Join';
              tip = 'In conference';
            }
            buttonWidget = CircleTextButton(
              label: label,
              tip: tip,
              onPressed: () async {
                if (conference == null) {
                  await _invite();
                } else {
                  await _join();
                }
              },
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.call,
                size: AppIconSize.mdSize,
                color: Colors.white,
              ),
            );
          } else {
            buttonWidget = const CircleTextButton(
              elevation: 2.0,
              backgroundColor: Colors.grey,
              padding: EdgeInsets.all(15.0),
              child: Icon(
                Icons.call_end,
                size: AppIconSize.mdSize,
                color: Colors.white,
              ),
            );
          }
          List<Widget> children = [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(0.0),
              child: buttonWidget,
            ),
          ];
          children.add(const SizedBox(
            height: 25.0,
          ));

          return Column(children: children);
        });
  }

  Future<void> _onClosedVideoRender(PeerVideoRender videoRender) async {
    localVideoRenderController.remove(videoRender);
    var videoChatMessageController = this.videoChatMessageController.value;
    if (videoChatMessageController != null &&
        videoChatMessageController.conference != null) {
      //在会议中，如果是本地流，先所有的连接中移除
      String conferenceId = videoChatMessageController.conference!.conferenceId;
      await videoConferenceRenderPool
          .removeVideoRender(conferenceId, [videoRender]);
    }
    localVideoRenderController.close(videoRender);
  }

  @override
  Widget build(BuildContext context) {
    var videoViewCard = GestureDetector(
      child: ValueListenableBuilder<int>(
          valueListenable: videoViewCount,
          builder: (context, value, child) {
            if (value > 0) {
              var videoChatMessageController =
                  this.videoChatMessageController.value;
              return VideoViewCard(
                videoRenderController: localVideoRenderController,
                onClosed: _onClosedVideoRender,
                conference: videoChatMessageController?.conference,
              );
            } else {
              var size = MediaQuery.of(context).size;
              return SizedBox(
                width: size.width,
                height: size.height,
              );
            }
          }),
      onLongPress: () {
        _toggleActionCardVisible();
      },
    );
    return Stack(children: [
      videoViewCard,
      _buildControlPanel(context),
    ]);
  }

  @override
  void dispose() {
    localVideoRenderController.unregisterVideoRenderOperator(
        VideoRenderOperator.remove.name, _updateVideoRender);
    var videoChatMessageController = this.videoChatMessageController.value;
    videoChatMessageController?.removeListener(_updateVideoChatStatus);
    videoChatMessageController?.unregisterReceiver(
        ChatMessageSubType.chatReceipt.name, _receivedChatReceipt);
    videoConferenceRenderPool.removeListener(_updateVideoChatMessageController);
    super.dispose();
  }
}
