import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group_linkman_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/p2p/video_view_card.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_room_client.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///sfu模式下本地视频通话显示和拨出的窗口，显示多个本地视频，音频和屏幕共享的小视频窗口
///各种功能按钮，创建会议，邀请参与者，加入会议，可以切换视频和音频，添加屏幕共享视频
class SfuLocalVideoWidget extends StatefulWidget {
  const SfuLocalVideoWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SfuLocalVideoWidgetState();
  }
}

class _SfuLocalVideoWidgetState extends State<SfuLocalVideoWidget> {
  /// 当前的视频会议的消息汇总（也就是知道会议目标是谁，比如是linkman，group还是conference）必须存在
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
  ValueNotifier<bool> speakerStatus = ValueNotifier<bool>(true);

  //控制面板可见性的计时器
  Timer? _hideControlPanelTimer;

  @override
  void initState() {
    super.initState();
    liveKitConferenceClientPool.addListener(_updateConferenceClient);
    localPeerMediaStreamController.addListener(_updateView);
    _updateConferenceClient();
    _updateView();
  }

  _updateConferenceClient() {
    LiveKitConferenceClient? conferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      ConferenceChatMessageController? conferenceChatMessageController =
          conferenceClient.conferenceChatMessageController;
      conferenceChatMessageController.addListener(_updateVideoChatStatus);
      videoChatStatus.value = conferenceChatMessageController.status;
    } else {
      videoChatStatus.value = VideoChatStatus.end;
    }
    _updateView();
  }

  _updateVideoChatStatus() {
    ConferenceChatMessageController? conferenceChatMessageController =
        liveKitConferenceClientPool.conferenceChatMessageController;
    if (conferenceChatMessageController != null) {
      videoChatStatus.value = conferenceChatMessageController.status;
      if (mounted) {
        DialogUtil.info(context,
            content: AppLocalizations.t('Video chat status:') +
                AppLocalizations.t(videoChatStatus.value.name));
      }
    }
  }

  /// 调整界面的显示
  Future<void> _updateView() async {
    List<ActionData> actionData = [];
    if (localPeerMediaStreamController.mainPeerMediaStream == null ||
        !localPeerMediaStreamController.video) {
      actionData.add(
        ActionData(
            label: 'Video',
            tooltip: 'Open local video',
            icon: const Icon(Icons.video_call, color: Colors.white)),
      );
    }
    if (localPeerMediaStreamController.mainPeerMediaStream == null ||
        localPeerMediaStreamController.video) {
      actionData.add(
        ActionData(
          label: 'Audio',
          tooltip: 'Open local audio',
          icon: const Icon(Icons.multitrack_audio, color: Colors.white),
        ),
      );
    }
    actionData.add(
      ActionData(
          label: 'Screen share',
          tooltip: 'Open screen share',
          icon: const Icon(Icons.screen_share, color: Colors.white)),
    );
    if (localPeerMediaStreamController.peerMediaStreams.isNotEmpty) {
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
    videoViewCount.value =
        localPeerMediaStreamController.peerMediaStreams.length;
    this.actionData.value = actionData;
  }

  _playAudio() {
    var conferenceChatMessageController =
        liveKitConferenceClientPool.conferenceChatMessageController;
    conferenceChatMessageController?.playAudio('assets/medias/call.mp3', true);
  }

  _stopAudio() async {
    var conferenceChatMessageController =
        liveKitConferenceClientPool.conferenceChatMessageController;
    conferenceChatMessageController?.stopAudio(
        filename: 'assets/medias/close.mp3');
  }

  /// 发布视频流
  _publish(PeerMediaStream peerMediaStream) async {
    LiveKitConferenceClient? conferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      await conferenceClient.publish(peerMediaStreams: [peerMediaStream]);
    }
  }

  ///创建本地的Video render，支持视频和音频的切换，设置当前videoChatRender，激活create。add和remove监听事件
  Future<PeerMediaStream?> _openMainPeerMediaStream({bool video = true}) async {
    ///本地视频不存在，可以直接创建，并发送视频邀请消息，否则根据情况觉得是否音视频切换
    PeerMediaStream? mainPeerMediaStream =
        localPeerMediaStreamController.mainPeerMediaStream;
    if (mainPeerMediaStream != null) {
      if (mainPeerMediaStream.video != video) {
        await _close(mainPeerMediaStream);
      } else {
        return null;
      }
    }
    if (video) {
      mainPeerMediaStream = await localPeerMediaStreamController
          .createMainPeerMediaStream(sfu: true);
    } else {
      mainPeerMediaStream = await localPeerMediaStreamController
          .createMainPeerMediaStream(video: false, sfu: true);
    }
    await _publish(mainPeerMediaStream);
    _updateView();

    return mainPeerMediaStream;
  }

  Future<PeerMediaStream?> _openDisplayMedia() async {
    DesktopCapturerSource? source;
    if (!platformParams.ios) {
      source = await DialogUtil.show<DesktopCapturerSource>(
        context: context,
        builder: (context) => Dialog(child: ScreenSelectDialog()),
      );
    }
    PeerMediaStream peerMediaStream = await localPeerMediaStreamController
        .createPeerDisplayStream(selectedSource: source, sfu: true);
    await _publish(peerMediaStream);
    _updateView();

    return peerMediaStream;
  }

  /// 关闭单个本地视频窗口的流
  _close(PeerMediaStream peerMediaStream) async {
    LiveKitConferenceClient? conferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      await conferenceClient.close([peerMediaStream]);
    }
  }

  ///关闭并且移除本地所有的视频，这时候还能看远程的视频
  _closeAll() async {
    LiveKitConferenceClient? conferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      await conferenceClient.closeAll();
    }
  }

  ///如果正在呼叫calling，停止呼叫，关闭所有的本地视频，呼叫状态改为结束
  ///如果正在通话chatting，挂断视频通话，关闭所有的本地视频和远程视频，呼叫状态改为结束
  ///结束会议，这时候本地和远程的视频都应该被关闭
  _disconnect() async {
    LiveKitConferenceClient? conferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      ConferenceChatMessageController conferenceChatMessageController =
          conferenceClient.conferenceChatMessageController;
      var status = conferenceChatMessageController.status;
      if (status == VideoChatStatus.calling ||
          status == VideoChatStatus.chatting) {
        await _closeAll();
        await liveKitConferenceClientPool.disconnect(
            conferenceId: conferenceChatMessageController.conferenceId!);
      }
      conferenceChatMessageController.status = VideoChatStatus.end;
    }
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Video':
        await _openMainPeerMediaStream();
        break;
      case 'Audio':
        await _openMainPeerMediaStream(video: false);
        break;
      case 'Screen share':
        await _openDisplayMedia();
        break;
      case 'Media play':
        //await _openMediaStream(stream);
        break;
      case 'Close':
        await _closeAll();
        break;
      default:
        break;
    }
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

  /// 邀请的时候，在group模式下创建新的会议
  Future<List<ChatMessage>> _buildSfuConference(
      {required bool video, required List<String> participants}) async {
    var current = DateTime.now();
    var dateName = current.toLocal().toIso8601String();
    Conference conference = await conferenceService.createConference(
        'video-chat-$dateName', video,
        startDate: current.toUtc().toIso8601String(),
        endDate:
            current.add(const Duration(hours: 2)).toUtc().toIso8601String(),
        participants: participants);

    var partyType = chatSummary.partyType;
    if (partyType == PartyType.group.name ||
        partyType == PartyType.conference.name) {
      conference.groupId = chatSummary.peerId;
      conference.groupName = chatSummary.name;
      conference.groupType = partyType;
      conference.sfu = true;
      conference.sfuUri = '';
    }
    try {
      List<ChatMessage> chatMessages =
          await chatMessageService.buildSfuConference(conference, participants);

      return chatMessages;
    } catch (e) {
      logger.e('buildSfuConference failure:$e');
      if (mounted) {
        DialogUtil.error(context, content: 'build sfu conference failure');
      }
    }

    return <ChatMessage>[];
  }

  /// 在group模式下创建会议，选择会议参与者，发送会议邀请消息，然后将新会议加入会议池，成为当前会议
  Future<void> _invite() async {
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
    //当前会议存在不能邀请
    ConferenceChatMessageController? conferenceChatMessageController =
        liveKitConferenceClientPool.conferenceChatMessageController;
    if (conferenceChatMessageController != null) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Current conference is exist'));
      }
      return;
    }

    ///根据本地视频决定音视频选项，如果没有则认为是音频
    bool? video = false;
    if (mounted) {
      video = await DialogUtil.confirm(context,
          content: 'Do you open video chat?',
          okLabel: 'Video',
          cancelLabel: 'Audio');
    }
    video ??= false;
    List<ChatMessage> chatMessages =
        await _buildSfuConference(video: video, participants: participants);
    ChatMessage chatMessage = chatMessages.first;
    if (mounted) {
      DialogUtil.info(context,
          content:
              '${AppLocalizations.t('Build sfu conference:')} ${chatMessage.messageId}');
    }

    ///根据邀请消息创建会议
    LiveKitConferenceClient? liveKitConferenceClient =
        await liveKitConferenceClientPool.createConferenceClient(
            chatSummary: chatSummary, chatMessage);
    if (liveKitConferenceClient == null ||
        conferenceChatMessageController == null) {
      logger.e('createLiveKitConferenceClient failure!');
      if (mounted) {
        DialogUtil.error(context,
            content:
                AppLocalizations.t('CreateLiveKitConferenceClient failure'));
      }
      return;
    }
    conferenceChatMessageController =
        liveKitConferenceClient.conferenceChatMessageController;
    conferenceChatMessageController.status = VideoChatStatus.calling;

    _playAudio();
    //延时60秒后自动挂断
    Future.delayed(const Duration(seconds: 30)).then((value) {
      //时间到了后，如果还是呼叫状态，则修改状态为结束
      if (conferenceChatMessageController?.status == VideoChatStatus.calling) {
        _stopAudio();
        conferenceChatMessageController?.status = VideoChatStatus.end;
      }
    });
    _updateView();
  }

  /// 当前会议存在的时候加入当前会议，即开始视频会议
  Future<void> _join() async {
    ConferenceChatMessageController? conferenceChatMessageController =
        liveKitConferenceClientPool.conferenceChatMessageController;
    if (conferenceChatMessageController == null) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('No video chat message controller'));
      }
      return;
    }
    ChatMessage? chatMessage = conferenceChatMessageController.chatMessage;
    if (chatMessage == null) {
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('No video chat message'));
      }
      return;
    }
    Conference? conference = conferenceChatMessageController.conference;
    if (conference == null) {
      if (mounted) {
        DialogUtil.error(context, content: AppLocalizations.t('No conference'));
      }
      return;
    }
    try {
      await conferenceChatMessageController.join();
    } catch (e) {
      logger.e('join failure:$e');
      if (mounted) {
        DialogUtil.error(context,
            content: AppLocalizations.t('Join conference failure:') +
                conferenceChatMessageController.name!);
      }
      return;
    }
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Join conference:') + conference.name);
    }
    _updateView();
  }

  Widget _buildActionCard(BuildContext context) {
    double height = 80;
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: ValueListenableBuilder<List<ActionData>>(
          valueListenable: actionData,
          builder: (context, value, child) {
            if (value.isNotEmpty) {
              return DataActionCard(
                actions: value,
                height: height,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                onPressed: _onAction,
                crossAxisCount: value.length,
                labelColor: Colors.white,
              );
            }
            return Container();
          }),
    );
  }

  ///切换显示按钮面板
  void _toggleActionCardVisible() {
    bool visible = false;
    LiveKitConferenceClient? conferenceClient =
        liveKitConferenceClientPool.conferenceClient;
    if (conferenceClient != null) {
      visible = localPeerMediaStreamController.peerMediaStreams.isEmpty;
    }
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
            label: 'Speaker',
            tip: status ? 'On' : 'Off',
            onPressed: () async {
              speakerStatus.value = !speakerStatus.value;
              var conferenceChatMessageController =
                  liveKitConferenceClientPool.conferenceChatMessageController;
              await MediaStreamUtil.setSpeakerphoneOn(status);
              // await conferenceChatMessageController?.setAudioContext(
              //     route: status
              //         ? AudioContextConfigRoute.speaker
              //         : AudioContextConfigRoute.system);
            },
            backgroundColor: status ? Colors.green : Colors.white,
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
          Widget buttonWidget = const CircleTextButton(
            elevation: 2.0,
            backgroundColor: Colors.grey,
            padding: EdgeInsets.all(15.0),
            child: Icon(
              Icons.call_end,
              size: AppIconSize.mdSize,
              color: Colors.white,
            ),
          );
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
                  _disconnect();
                } else if (value == VideoChatStatus.chatting) {
                  _disconnect();
                  indexWidgetProvider.pop(context: context);
                }
              },
              backgroundColor: Colors.red,
              child: const Icon(
                Icons.call_end,
                size: AppIconSize.mdSize,
                color: Colors.white,
              ),
            );
            if ((value == VideoChatStatus.calling ||
                    value == VideoChatStatus.chatting) &&
                platformParams.mobile) {
              buttonWidget =
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                buttonWidget,
                const SizedBox(
                  width: 50.0,
                ),
                _buildSpeakerSwitchButton(context),
              ]);
            }
          } else if (value == VideoChatStatus.end) {
            String? label;
            String? tip;
            ConferenceChatMessageController? conferenceChatMessageController =
                liveKitConferenceClientPool.conferenceChatMessageController;
            String? partyType = chatSummary.partyType;
            Conference? conference =
                conferenceChatMessageController?.conference;
            bool validConference = true;
            if (conference != null) {
              validConference = conferenceService.isValid(conference);
            }
            if (partyType == PartyType.conference.name) {
              if (conference == null) {
                label = 'Error';
                tip = 'No conference';
              } else {
                label = 'Join';
                tip = 'In conference';
              }
            } else {
              if (conference == null) {
                label = 'Invite';
                tip = 'No conference';
              } else {
                label = 'Join';
                tip = 'In conference';
              }
            }
            if (validConference) {
              buttonWidget = CircleTextButton(
                label: label,
                tip: tip,
                onPressed: () async {
                  if (conference == null) {
                    if (partyType != PartyType.conference.name) {
                      await _invite();
                    }
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
              logger.e('conference ${conference?.name} is invalid');
            }
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

  ///关闭单个本地视频窗口的流
  Future<void> _onClosedPeerMediaStream(PeerMediaStream peerMediaStream) async {
    await _close(peerMediaStream);
  }

  @override
  Widget build(BuildContext context) {
    var videoViewCard = ValueListenableBuilder<int>(
        valueListenable: videoViewCount,
        builder: (context, value, child) {
          if (value > 0) {
            return VideoViewCard(
              peerMediaStreamController: localPeerMediaStreamController,
              onClosed: _onClosedPeerMediaStream,
            );
          } else {
            var size = MediaQuery.of(context).size;
            return SizedBox(
              width: size.width,
              height: size.height,
            );
          }
        });
    return GestureDetector(
        onDoubleTap: () {
          _toggleActionCardVisible();
        },
        child: Stack(children: [
          videoViewCard,
          _buildControlPanel(context),
        ]));
  }

  @override
  void dispose() {
    var conferenceChatMessageController =
        liveKitConferenceClientPool.conferenceChatMessageController;
    conferenceChatMessageController?.removeListener(_updateVideoChatStatus);
    liveKitConferenceClientPool.removeListener(_updateConferenceClient);
    localPeerMediaStreamController.removeListener(_updateView);
    conferenceChatMessageController?.stopAudio();
    super.dispose();
  }
}
