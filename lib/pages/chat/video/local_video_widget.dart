import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group_linkman_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/video/video_view_card.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum VideoChatStatus {
  chatting, //正在视频中，只要开始重新协商，表明进入
  calling, //正在呼叫中，发送邀请消息后，等待固定时间的振铃或者有人回答接受或者拒绝邀请后结束
  end, //结束
}

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
  final VideoChatMessageController videoChatMessageController;

  const LocalVideoWidget({Key? key, required this.videoChatMessageController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LocalVideoWidgetState();
  }
}

class _LocalVideoWidgetState extends State<LocalVideoWidget> {
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

  //控制面板可见性的计时器
  Timer? _hideControlPanelTimer;

  //呼叫时间的计时器，如果是在单聊的场景下，对方在时间内未有回执，则自动关闭
  Timer? _linkmanCallTimer;

  BlueFireAudioPlayer audioPlayer = BlueFireAudioPlayer();

  //JustAudioPlayer audioPlayer = JustAudioPlayer();

  @override
  void initState() {
    super.initState();
    //视频通话的消息存放地
    widget.videoChatMessageController.addListener(_updateVideoChatReceipt);
    //本地视频的存放地
    localVideoRenderController.registerVideoRenderOperator(
        VideoRenderOperator.add.name, _addLocalVideoRender);
    localVideoRenderController.registerVideoRenderOperator(
        VideoRenderOperator.remove.name, _removeLocalVideoRender);
    _buildActionDataAndVisible();
    if (widget.videoChatMessageController.conference == null) {
      videoChatStatus.value = VideoChatStatus.end;
    } else {
      videoChatStatus.value = VideoChatStatus.chatting;
    }
  }

  Future<void> _addLocalVideoRender(PeerVideoRender? videoRender) async {
    addLocalVideoRender(videoRender!);
    if (mounted) {
      _buildActionDataAndVisible();
    }
    videoViewCount.value = localVideoRenderController.videoRenders.length;
  }

  Future<void> _removeLocalVideoRender(PeerVideoRender? videoRender) async {
    removeLocalVideoRender(videoRender!);
    if (mounted) {
      _buildActionDataAndVisible();
    }
    videoViewCount.value = localVideoRenderController.videoRenders.length;
  }

  ///如果视频邀请消息的回执到来，如果不在此界面的时候，新的回执不会被此处理
  _updateVideoChatReceipt() async {
    ChatMessage? chatReceipt = widget.videoChatMessageController.current;
    if (chatReceipt == null) {
      return;
    }
    if (chatReceipt.subMessageType != ChatMessageSubType.chatReceipt.name) {
      return;
    }
    if (chatReceipt.status == MessageStatus.rejected.name) {
      videoChatStatus.value = VideoChatStatus.end;
    }
    _stop();
  }

  _play() {
    audioPlayer.setLoopMode(true);
    audioPlayer.play('assets/medias/call.mp3');
  }

  _stop() {
    audioPlayer.setLoopMode(true);
    audioPlayer.play('assets/medias/close.mp3');
  }

  ///调整显示哪些命令按钮
  _buildActionDataAndVisible() {
    List<ActionData> actionData = [];
    if (localVideoRenderController.videoChatRender == null ||
        !localVideoRenderController.video) {
      actionData.add(
        ActionData(
            label: 'Video',
            tooltip: 'Open local video',
            icon: const Icon(Icons.video_call, color: Colors.white)),
      );
    }
    if (localVideoRenderController.videoChatRender == null ||
        localVideoRenderController.video) {
      actionData.add(
        ActionData(
          label: 'Audio',
          tooltip: 'Open local audio',
          icon: const Icon(Icons.multitrack_audio, color: Colors.white),
        ),
      );
    }
    if (localVideoRenderController.videoChatRender != null) {
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
      videoViewCount.value = localVideoRenderController.videoRenders.length;
      actionData.add(
        ActionData(
            label: 'Close',
            tooltip: 'Close all video',
            icon:
                const Icon(Icons.closed_caption_disabled, color: Colors.white)),
      );
    } else {
      videoViewCount.value = localVideoRenderController.videoRenders.length;
      controlPanelVisible.value = true;
    }
    this.actionData.value = actionData;
  }

  ///创建新的会议功能
  ///对联系人模式，可以临时创建一个会议，会议成员从群成员中选择就是自己和对方，会议名称是对方的名称，不保存会议
  ///对群模式，可以创建一个会议，会议成员从群成员中选择，会议名称是群的名称加上当前时间，保存会议
  ///对会议模式，直接转到会议创建界面，
  Future<Conference?> _buildConference({bool video = true}) async {
    var conference = widget.videoChatMessageController.conference;
    if (conference != null) {
      logger.e('conference ${conference.name} is exist');
      return conference;
    }
    List<String> participants = [myself.peerId!];
    var partyType = widget.videoChatMessageController.partyType;
    if (partyType == PartyType.conference.name) {
      List<String> selected = <String>[];
      await DialogUtil.show(
          context: context,
          // title: AppBarWidget.buildTitleBar(
          //     title: Text(AppLocalizations.t('Select one linkman'))),
          builder: (BuildContext context) {
            return LinkmanGroupSearchWidget(
                onSelected: (List<String>? peerIds) async {
                  if (peerIds != null) {
                    participants.addAll(peerIds);
                  }
                  Navigator.pop(context, participants);
                },
                selected: selected,
                includeGroup: false,
                selectType: SelectType.chipMultiSelect);
          });
    }
    var groupPeerId = widget.videoChatMessageController.groupPeerId;
    if (partyType == PartyType.group.name) {
      if (groupPeerId == null) {
        return null;
      }
      if (conference != null) {
        return conference;
      }
      if (mounted) {
        await DialogUtil.show(
            context: context,
            builder: (BuildContext context) {
              return GroupLinkmanWidget(
                onSelected: (List<String> peerIds) {
                  participants.addAll(peerIds);
                  Navigator.pop(context, participants);
                },
                selected: const <String>[],
                groupPeerId: groupPeerId,
              );
            });
      }
    }
    if (partyType == PartyType.linkman.name) {
      var peerId = widget.videoChatMessageController.peerId;
      if (peerId == null) {
        return null;
      }
      participants.add(peerId);
    }
    var name = widget.videoChatMessageController.name;
    conference = await conferenceService.createConference(
        '${name!}-${DateUtil.currentDate()}',
        video: video,
        participants: participants);
    if (partyType == PartyType.group.name) {
      conference.groupPeerId = groupPeerId;
      conference.groupName = name;
      conference.groupType = partyType;
    }
    if (mounted) {
      DialogUtil.info(context,
          content:
              '${AppLocalizations.t('Create conference')} ${conference.conferenceId}');
    }

    return conference;
  }

  Future<PeerVideoRender?> _openVideoMedia({bool video = true}) async {
    ///本地视频不存在，可以直接创建，并发送视频邀请消息，否则根据情况觉得是否音视频切换
    PeerVideoRender? videoRender = localVideoRenderController.videoChatRender;
    if (videoRender == null) {
      if (video) {
        videoRender = await localVideoRenderController.createVideoMediaRender();
      } else {
        videoRender = await localVideoRenderController.createAudioMediaRender();
      }
      addLocalVideoRender(videoRender);
    } else {
      if (video) {
        if (!localVideoRenderController.video) {
          removeLocalVideoRender(videoRender);
          videoRender =
              await localVideoRenderController.createVideoMediaRender();
          addLocalVideoRender(videoRender);
        }
      } else {
        if (localVideoRenderController.video) {
          removeLocalVideoRender(videoRender);
          videoRender =
              await localVideoRenderController.createAudioMediaRender();
          addLocalVideoRender(videoRender);
        }
      }
    }
    return videoRender;
  }

  Future<PeerVideoRender?> _openDisplayMedia() async {
    final source = await DialogUtil.show<DesktopCapturerSource>(
      context: context,
      builder: (context) => Dialog(child: ScreenSelectDialog()),
    );
    if (source != null) {
      PeerVideoRender videoRender = await localVideoRenderController
          .createDisplayMediaRender(selectedSource: source);
      addLocalVideoRender(videoRender);
      return videoRender;
    }
    return null;
  }

  Future<PeerVideoRender?> _openMediaStream(MediaStream stream) async {
    ChatMessage? chatMessage = widget.videoChatMessageController.chatMessage;
    if (chatMessage == null) {
      DialogUtil.error(context, content: AppLocalizations.t('No conference'));
      return null;
    }
    PeerVideoRender? videoRender =
        await localVideoRenderController.createMediaStreamRender(stream);
    addLocalVideoRender(videoRender);

    return videoRender;
  }

  addLocalVideoRender(PeerVideoRender videoRender) {
    Conference? conference = widget.videoChatMessageController.conference;

    if (conference != null &&
        videoChatStatus.value == VideoChatStatus.chatting) {
      videoConferenceRenderPool.addLocalVideoRender(
          conference.conferenceId, videoRender);
    }
  }

  removeLocalVideoRender(PeerVideoRender videoRender) {
    Conference? conference = widget.videoChatMessageController.conference;

    if (conference != null &&
        videoChatStatus.value == VideoChatStatus.chatting) {
      videoConferenceRenderPool.removeLocalVideoRender(
          conference.conferenceId, videoRender);
    }
  }

  ///呼叫，打开本地视频，如果没有会议，先创建会议，发送视频通话邀请消息
  ///如果已有视频通话邀请消息，则直接开始重新协商
  _call() async {
    var name = widget.videoChatMessageController.name;
    var partyType = widget.videoChatMessageController.partyType;
    var peerId = widget.videoChatMessageController.peerId;
    if (partyType == PartyType.linkman.name && peerId != null) {
      var status = peerConnectionPool.status(peerId);
      if (status != PeerConnectionStatus.connected) {
        DialogUtil.error(context,
            content:
                '$name ${AppLocalizations.t('has no Webrtc connected PeerConnection')}');
        return null;
      }
    }
    //确保本地视频已经被打开
    PeerVideoRender? videoChatRender =
        localVideoRenderController.videoChatRender;
    videoChatRender ??= await _openVideoMedia(video: true);
    if (videoChatRender == null) {
      return;
    }
    var conference = widget.videoChatMessageController.conference;
    //创建会议
    conference ??= await _buildConference(video: videoChatRender.video);
    //检查当前的视频邀请消息是否存在
    ChatMessage? chatMessage = widget.videoChatMessageController.chatMessage;
    if (chatMessage == null) {
      //在联系人模式下，会议不保存，在群模式下，在邀请消息发送后才保存
      //在会议模式下，会议在创建后保存，直接发送邀请消息和保存
      if (partyType == PartyType.group.name) {
        await conferenceService.store(conference!);
      }
      //发送会议邀请消息
      if (videoChatRender.video) {
        chatMessage = await _sendVideoChatMessage(
            contentType: ContentType.video.name, conference: conference!);
      } else {
        chatMessage = await _sendVideoChatMessage(
            contentType: ContentType.audio.name, conference: conference!);
      }
      await widget.videoChatMessageController.setChatMessage(chatMessage);
      // videoConferenceRenderPool
      //     .createRemoteVideoRenderController(widget.videoChatMessageController);
    } else {
      //当前视频消息不为空，则有同意回执的直接重新协商
      var messageId = chatMessage.messageId!;
      logger.i('current video chatMessage $messageId');
      var videoRoomRenderController =
          videoConferenceRenderPool.getRemoteVideoRenderController(messageId);
      if (videoRoomRenderController != null) {
        List<AdvancedPeerConnection> pcs =
            videoRoomRenderController.getAdvancedPeerConnections(peerId!);
        if (pcs.isNotEmpty) {
          for (var pc in pcs) {
            pc.negotiate();
          }
        }
      }
    }
    videoChatStatus.value = VideoChatStatus.calling;
    _play();
    //延时60秒后自动挂断
    Future.delayed(const Duration(seconds: 60)).then((value) {
      if (videoChatStatus.value != VideoChatStatus.end) {
        _stop();
      }
    });
  }

  ///如果正在呼叫calling，停止呼叫，关闭所有的本地视频，呼叫状态改为结束
  ///如果正在通话chatting，挂断视频通话，关闭所有的本地视频和远程视频，呼叫状态改为结束
  _close() async {
    if (videoChatStatus.value == VideoChatStatus.calling) {
      localVideoRenderController.close();
    }
    if (videoChatStatus.value == VideoChatStatus.chatting) {
      localVideoRenderController.close();
      widget.videoChatMessageController.setChatMessage(null);
    }
    _stop();
    videoChatStatus.value = VideoChatStatus.end;
  }

  ///发送group视频通邀请话消息,此时消息必须有content,包含conference信息
  ///conference的participants，而不是group的所有成员
  ///title字段存放是视频还是音频的信息
  Future<ChatMessage?> _sendVideoChatMessage(
      {required String contentType, required Conference conference}) async {
    ChatMessage? chatMessage = await chatMessageController.send(
        title: contentType,
        content: conference,
        messageId: conference.conferenceId,
        subMessageType: ChatMessageSubType.videoChat,
        peerIds: conference.participants);
    if (chatMessage != null) {
      logger.i('send video chatMessage ${chatMessage.messageId}');
    }

    return chatMessage;
  }

  Future<void> _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Video':
        _openVideoMedia();
        break;
      case 'Audio':
        _openVideoMedia(video: false);
        break;
      case 'Screen share':
        _openDisplayMedia();
        break;
      case 'Media play':
        //_openMediaStream(stream);
        break;
      case 'Close':
        _close();
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

  ///创建呼叫按钮
  Widget _buildCallButton() {
    return ValueListenableBuilder<VideoChatStatus>(
        valueListenable: videoChatStatus,
        builder: (BuildContext context, VideoChatStatus value, Widget? child) {
          Widget buttonWidget;
          if (value == VideoChatStatus.calling ||
              value == VideoChatStatus.chatting) {
            buttonWidget = WidgetUtil.buildCircleButton(
              onPressed: () {
                _close();
              },
              elevation: 2.0,
              backgroundColor: Colors.red,
              padding: const EdgeInsets.all(15.0),
              child: const Icon(
                Icons.call_end,
                size: 48.0,
                color: Colors.white,
              ),
            );
          } else if (value == VideoChatStatus.end) {
            buttonWidget = WidgetUtil.buildCircleButton(
              onPressed: () {
                _call();
              },
              elevation: 2.0,
              backgroundColor: Colors.green,
              padding: const EdgeInsets.all(15.0),
              child: const Icon(
                Icons.call,
                size: 48.0,
                color: Colors.white,
              ),
            );
          } else {
            buttonWidget = WidgetUtil.buildCircleButton(
              elevation: 2.0,
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.all(15.0),
              child: const Icon(
                Icons.call_end,
                size: 48.0,
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
          var conference = widget.videoChatMessageController.conference;
          if (conference != null) {
            children.add(
              Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                          '${AppLocalizations.t('conferenceId')}:${conference.conferenceId}',
                          style: const TextStyle(color: Colors.white)))),
            );
          } else {
            children.add(const SizedBox(
              height: 25.0,
            ));
          }

          return Column(children: children);
        });
  }

  @override
  Widget build(BuildContext context) {
    var videoViewCard = GestureDetector(
      child: ValueListenableBuilder<int>(
          valueListenable: videoViewCount,
          builder: (context, value, child) {
            if (value > 0) {
              return VideoViewCard(
                videoRenderController: localVideoRenderController,
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
        VideoRenderOperator.remove.name, _removeLocalVideoRender);
    localVideoRenderController.unregisterVideoRenderOperator(
        VideoRenderOperator.add.name, _addLocalVideoRender);
    widget.videoChatMessageController.removeListener(_updateVideoChatReceipt);
    super.dispose();
  }
}
