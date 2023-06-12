import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/channel/subscribe_channel_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/me/me_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:provider/provider.dart';

///主工作区，是PageView
class IndexWidget extends StatefulWidget {
  IndexWidget({Key? key}) : super(key: key) {
    PageController controller = PageController();
    indexWidgetProvider.controller = controller;
    indexWidgetProvider.define(ChatListWidget());
    indexWidgetProvider.define(LinkmanListWidget());
    indexWidgetProvider.define(SubscribeChannelListWidget());
    indexWidgetProvider.define(MeWidget());
  }

  @override
  State<StatefulWidget> createState() {
    return _IndexWidgetState();
  }
}

class _IndexWidgetState extends State<IndexWidget>
    with SingleTickerProviderStateMixin {
  late StreamSubscription _intentDataStreamSubscription;
  late List<SharedFile> _sharedFiles;

  @override
  void initState() {
    _initShare();
    super.initState();
  }

  ///初始化应用数据接受分享的监听器
  _initShare() {
    if (!platformParams.mobile) {
      return;
    }
    // 应用打开时分享的媒体文件
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedFile> value) {
      _sharedFiles = value;
      if (_sharedFiles.isNotEmpty) {
        _shareChatMessage(_sharedFiles.first);
      }
    }, onError: (err) {
      logger.e("getIntentDataStream error: $err");
    });

    // 应用关闭时分享的媒体文件
    FlutterSharingIntent.instance
        .getInitialSharing()
        .then((List<SharedFile> value) {
      _sharedFiles = value;
      if (_sharedFiles.isNotEmpty) {
        _shareChatMessage(_sharedFiles.first);
      }
    });
  }

  Future<void> _shareChatMessage(SharedFile file) async {
    String? content = file.value;
    String? thumbnail = file.thumbnail;
    SharedMediaType type = file.type;
    if (type == SharedMediaType.URL) {
      content = '#$content#';
    }
    await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return LinkmanGroupSearchWidget(
              onSelected: (List<String>? selected) async {
                if (selected != null && selected.isNotEmpty) {
                  String? receivePeerId;
                  Linkman? linkman =
                      await linkmanService.findCachedOneByPeerId(selected[0]);
                  if (linkman != null) {
                    receivePeerId = linkman.peerId;
                  } else {
                    Group? group =
                        await groupService.findCachedOneByPeerId(selected[0]);
                    if (group != null) {
                      receivePeerId = group.peerId;
                    }
                  }
                  if (receivePeerId != null) {
                    ChatSummary? current = await chatSummaryService
                        .findCachedOneByPeerId(receivePeerId);
                    if (current != null) {
                      chatMessageController.chatSummary = current;
                      indexWidgetProvider.push('chat_message');
                      if (type == SharedMediaType.TEXT ||
                          type == SharedMediaType.URL) {
                        ChatMessageContentType contentType =
                            ChatMessageContentType.text;
                        if (type == SharedMediaType.URL) {
                          contentType = ChatMessageContentType.url;
                        }
                        await chatMessageController.sendText(
                            message: content, contentType: contentType);
                      } else if (type == SharedMediaType.VIDEO ||
                          type == SharedMediaType.IMAGE ||
                          type == SharedMediaType.FILE) {
                        ChatMessageContentType contentType =
                            ChatMessageContentType.file;
                        if (type == SharedMediaType.VIDEO) {
                          contentType = ChatMessageContentType.video;
                        }
                        if (type == SharedMediaType.IMAGE) {
                          contentType = ChatMessageContentType.image;
                        }
                        String filename = content!;
                        Uint8List? data = await FileUtil.readFile(filename);
                        if (data != null) {
                          String? mimeType = FileUtil.mimeType(filename);
                          mimeType = mimeType ?? 'text/plain';
                          await chatMessageController.send(
                              title: filename,
                              content: data,
                              thumbnail: thumbnail,
                              contentType: contentType,
                              mimeType: mimeType);
                        }
                      }
                    }
                  }
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              selected: const <String>[],
              selectType: SelectType.chipMultiSelect);
        });
  }

  ///workspace工作区视图
  Widget _createPageView(BuildContext context) {
    var pageView = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      ScrollPhysics? physics = const NeverScrollableScrollPhysics();
      if (!indexWidgetProvider.bottomBarVisible) {
        physics = null;
      }
      return PageView.builder(
        physics: physics,
        controller: indexWidgetProvider.controller,
        onPageChanged: (int index) {
          indexWidgetProvider.currentIndex = index;
        },
        itemCount: indexWidgetProvider.views.length,
        itemBuilder: (BuildContext context, int index) {
          var view = indexWidgetProvider.views[index];
          return view;
        },
      );
    });

    return pageView;
  }

  @override
  Widget build(BuildContext context) {
    var pageView = _createPageView(context);
    return pageView;
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }
}
