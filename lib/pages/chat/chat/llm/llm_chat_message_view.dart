import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/llm_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/llm/llm_chat_message_input.dart';
import 'package:colla_chat/pages/chat/chat/llm/llm_chat_message_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 大模型聊天界面
class LlmChatMessageView extends StatelessWidget with DataTileMixin {
  final LlmChatMessageWidget llmChatMessageWidget = LlmChatMessageWidget();
  final LlmChatMessageInputWidget llmChatMessageInputWidget =
      LlmChatMessageInputWidget();

  LlmChatMessageView({
    super.key,
  }) {
    WakelockPlus.enable();

    ///不准截屏
    if (platformParams.mobile) {
      try {
        noScreenshot = NoScreenshot.instance;
        screenshotCallback = ScreenshotCallback();
        noScreenshot!.screenshotOff();
        screenshotCallback!.addListener(() {
          logger.w('screenshot');
        });
      } catch (e) {
        logger.e('screenshotOff failure:$e');
      }
    }

    _buildReadStatus();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'llm_chat_message';

  @override
  IconData get iconData => Icons.auto_mode;

  @override
  String get title => 'LlmChatMessage';

  

  double visibleFraction = 0.0;
  NoScreenshot? noScreenshot;
  ScreenshotCallback? screenshotCallback;

  ///更新为已读状态
  Future<void> _buildReadStatus() async {
    var chatSummary = llmChatMessageController.chatSummary;
    if (chatSummary == null) {
      logger.e('chatSummary is null');
      return;
    }
    String peerId = chatSummary.peerId!;
    await chatMessageService.update(
        {'status': MessageStatus.read.name, 'readTime': DateUtil.currentDate()},
        where:
            'senderPeerId = ? and receiverPeerId = ? and readTime is null and (status=? or status=? or status=? or status=?)',
        whereArgs: [
          peerId,
          myself.peerId!,
          MessageStatus.unsent.name,
          MessageStatus.sent.name,
          MessageStatus.received.name,
          MessageStatus.send.name
        ]);
    if (chatSummary.unreadNumber > 0) {
      chatSummary.unreadNumber = 0;
      Map<String, dynamic> entity = {'unreadNumber': 0};
      await chatSummaryService
          .update(entity, where: 'peerId=?', whereArgs: [peerId]);
      if (chatSummary.partyType == PartyType.linkman.name) {
        linkmanChatSummaryController.refresh();
      }
    }
  }

  ///创建KeyboardActionsConfig钩住所有的字段
  KeyboardActionsConfig _buildKeyboardActionsConfig(BuildContext context) {
    List<KeyboardActionsItem> actions = [
      KeyboardActionsItem(
        focusNode: chatMessageViewController.focusNode,
        displayActionBar: false,
        displayArrows: false,
        displayDoneButton: false,
      )
    ];
    KeyboardActionsPlatform keyboardActionsPlatform =
        KeyboardActionsPlatform.ALL;
    if (platformParams.ios) {
      keyboardActionsPlatform = KeyboardActionsPlatform.IOS;
    } else if (platformParams.android) {
      keyboardActionsPlatform = KeyboardActionsPlatform.ANDROID;
    }
    return KeyboardActionsConfig(
      keyboardActionsPlatform: keyboardActionsPlatform,
      keyboardBarColor: myself.primary,
      nextFocus: false,
      actions: actions,
    );
  }

  ///创建消息显示面板，包含消息的输入框
  Widget _buildChatMessageWidget(BuildContext context) {
    final Widget chatMessageView = Obx(() {
      var height = chatMessageViewController.chatMessageHeight;
      Widget chatMessageWidget =
          SizedBox(height: height, child: llmChatMessageWidget);
      return VisibilityDetector(
          key: UniqueKey(),
          onVisibilityChanged: (VisibilityInfo visibilityInfo) {
            if (visibleFraction == 0.0 && visibilityInfo.visibleFraction > 0) {}
            visibleFraction = visibilityInfo.visibleFraction;
          },
          child: KeyboardActions(
              autoScroll: true,
              config: _buildKeyboardActionsConfig(context),
              child: Column(children: <Widget>[
                chatMessageWidget,
                Divider(
                  color: Colors.white.withAlpha(AppOpacity.xlOpacity),
                  height: 1.0,
                ),
                llmChatMessageInputWidget
              ])));
    });

    return chatMessageView;
  }

  @override
  Widget build(BuildContext context) {
    Widget appBarView = Obx(() {
      _buildReadStatus();
      Widget chatMessageWidget = _buildChatMessageWidget(context);
      var chatSummary = llmChatMessageController.chatSummary;
      if (chatSummary != null) {
        String name = chatSummary.name!;
        String title = AppLocalizations.t(name);
        return AppBarView(
            title: title, helpPath: routeName,withLeading: withLeading, child: chatMessageWidget);
      }
      return AppBarView(
          title: AppLocalizations.t('No current chatSummary'),
          helpPath: routeName,
          withLeading: withLeading,
          child: chatMessageWidget);
    });

    return appBarView;
  }

  void dispose() {
    WakelockPlus.disable();
    if (platformParams.mobile) {
      screenshotCallback?.dispose();
    }
  }
}
