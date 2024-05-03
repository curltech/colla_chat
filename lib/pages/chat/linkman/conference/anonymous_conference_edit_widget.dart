import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

///根据token创建匿名的SFU会议
class AnonymousConferenceEditWidget extends StatefulWidget with TileDataMixin {
  const AnonymousConferenceEditWidget({super.key});

  @override
  IconData get iconData => Icons.panorama_wide_angle_outlined;

  @override
  String get routeName => 'anonymous_conference_edit';

  @override
  String get title => 'Anonymous conference edit';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _AnonymousConferenceEditWidgetState();
}

class _AnonymousConferenceEditWidgetState
    extends State<AnonymousConferenceEditWidget> {
  final List<PlatformDataField> conferenceDataField = [
    PlatformDataField(
      name: 'sfuUri',
      label: 'SfuUri',
      inputType: InputType.text,
      dataType: DataType.string,
      prefixIcon: Icon(Icons.edit_location_outlined, color: myself.primary),
      readOnly: true,
    ),
    PlatformDataField(
      name: 'sfuToken',
      label: 'SfuToken',
      inputType: InputType.textarea,
      dataType: DataType.string,
      prefixIcon: Icon(Icons.token, color: myself.primary),
      readOnly: true,
    ),
  ];
  late final FormInputController controller =
      FormInputController(conferenceDataField);

  @override
  initState() {
    Conference? current = conferenceNotifier.value;
    if (current == null) {
      current = Conference('', name: '');
      conferenceNotifier.value = current;
    }
    conferenceController.addListener(_update);
    super.initState();
  }

  _update() {
    if (mounted) {}
  }

  //会议信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = ValueListenableBuilder(
        valueListenable: conferenceNotifier,
        builder: (BuildContext context, Conference? conference, Widget? child) {
          if (conference != null) {
            controller.setValues(JsonUtil.toJson(conference));
          }
          return FormInputWidget(
            spacing: 5.0,
            height: appDataProvider.portraitSize.height * 0.6,
            onOk: (Map<String, dynamic> values) {
              _onOk(values).then((conference) {
                if (conference != null) {
                  DialogUtil.info(context,
                      content: AppLocalizations.t('Built conference ') +
                          conference.name);
                }
              });
            },
            controller: controller,
          );
        });

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: formInputWidget);
  }

  //修改提交
  Future<Conference?> _onOk(Map<String, dynamic> values) async {
    bool conferenceModified = true;
    Conference? current = conferenceNotifier.value;
    if (current!.id == null) {
      var uuid = const Uuid();
      String conferenceId = uuid.v4();
      current = Conference(conferenceId, name: AppLocalizations.t('anonymous'));
      conferenceNotifier.value = current;
      conferenceModified = false;
    }

    if (StringUtil.isEmpty(values['sfuUri'])) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference sfuUri'));
      return null;
    }
    if (StringUtil.isEmpty(values['sfuToken'])) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has conference sfuToken'));
      return null;
    }
    current.sfuUri = values['sfuUri'];
    current.sfuToken = values['sfuToken'];
    current.sfu = true;
    await conferenceService.store(current);
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Conference has stored completely'));
    }
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
      receiverPeerId: myself.peerId,
      content: current,
      messageId: current.conferenceId,
      subMessageType: ChatMessageSubType.videoChat,
    );
    await chatMessageService.store(chatMessage);
    if (conferenceController.current == null) {
      conferenceController.add(current);
    }
    if (conferenceModified) {
      conferenceChatSummaryController.refresh();
    } else {
      setState(() {});
    }

    return current;
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add anonymous conference';
    if (conferenceNotifier.value?.id != null) {
      title = 'Edit anonymous conference';
    }

    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    conferenceNotifier.removeListener(_update);
    super.dispose();
  }
}
