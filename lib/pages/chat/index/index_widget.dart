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
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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
  late List<SharedMediaFile> _sharedFiles;
  late String _sharedText;

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
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      logger.i("Shared:${_sharedFiles.map((f) => f.path).join(",") ?? ""}");
      _sharedFiles = value;
      _shareChatMessage(file: _sharedFiles.first);
    }, onError: (err) {
      logger.e("getIntentDataStream error: $err");
    });

    // 应用关闭时分享的媒体文件
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      _sharedFiles = value;
      _shareChatMessage(file: _sharedFiles.first);
    });

    // 应用打开时分享的文本
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      _sharedText = value;
      _shareChatMessage(content: _sharedText);
    }, onError: (err) {
      logger.e("getLinkStream error: $err");
    });

    // 应用关闭时分享的文本
    ReceiveSharingIntent.getInitialText().then((String? value) {
      _sharedText = value!;
      _shareChatMessage(content: _sharedText);
    });
  }

  Future<void> _shareChatMessage(
      {SharedMediaFile? file, String? content}) async {
    if (file == null && content == null) {
      return;
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
                      if (content != null) {
                        await chatMessageController.sendText(message: content);
                      }
                      if (file != null) {
                        String filename = file.path;
                        String? thumbnail = file.thumbnail;
                        Uint8List? data = await FileUtil.readFile(filename);
                        if (data != null) {
                          String? mimeType = FileUtil.mimeType(filename);
                          mimeType = mimeType ?? 'text/plain';
                          await chatMessageController.send(
                              title: filename,
                              content: data,
                              // thumbnail: thumbnail,
                              contentType: ChatMessageContentType.file,
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
}
