import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> chatGPTColumnFieldDefs = [
  ColumnFieldDef(
      name: 'peerId',
      label: 'ApiKey',
      prefixIcon: Icon(
        Icons.key,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'peerPublicKey',
      label: 'Model',
      prefixIcon: Icon(
        Icons.model_training,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'name',
      label: 'LoginName',
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'alias',
      label: 'Organization',
      prefixIcon: Icon(
        Icons.person_pin,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'email',
      label: 'Email',
      prefixIcon: Icon(
        Icons.email,
        color: myself.primary,
      ),
      inputType: InputType.text),
  ColumnFieldDef(
      name: 'publicKey',
      label: 'Password',
      inputType: InputType.password,
      prefixIcon: Icon(
        Icons.password,
        color: myself.primary,
      )),
];

//联系人信息页面
class ChatGPTAddWidget extends StatefulWidget with TileDataMixin {
  const ChatGPTAddWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatGPTAddWidgetState();

  @override
  String get routeName => 'chat_gpt_add';

  @override
  bool get withLeading => true;

  @override
  dynamic get iconData => ImageUtil.buildImageWidget(
      image: 'assets/images/openai.png',
      width: AppIconSize.smSize,
      height: AppIconSize.smSize);

  @override
  String get title => 'Add chatGPT';
}

class _ChatGPTAddWidgetState extends State<ChatGPTAddWidget> {
  Linkman? linkman;

  @override
  initState() {
    super.initState();
    strangerController.addListener(_update);
    linkman ??= strangerController.current;
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    Map<String, dynamic>? initValues =
        strangerController.getInitValue(chatGPTColumnFieldDefs);

    var formInputWidget = Container(
        padding: const EdgeInsets.all(15.0),
        child: FormInputWidget(
          height: 420,
          onOk: (Map<String, dynamic> values) {
            _onOk(values);
          },
          columnFieldDefs: chatGPTColumnFieldDefs,
          initValues: initValues,
        ));

    return ListView(children: [formInputWidget]);
  }

  _onOk(Map<String, dynamic> values) async {
    if (values['peerId'] == null) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must have apiKey'));
      return;
    }
    if (values['name'] == null) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must have loginName'));
      return;
    }
    if (values['alias'] == null) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must have organization'));
      return;
    }
    if (values['publicKey'] == null) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must have password'));
      return;
    }
    Linkman currentLinkman = Linkman.fromJson(values);
    linkman ??= Linkman(currentLinkman.peerId, currentLinkman.name);
    linkman!.peerId = currentLinkman.peerId;
    linkman!.name = currentLinkman.name;
    linkman!.alias = currentLinkman.alias;
    linkman!.mobile = currentLinkman.mobile;
    linkman!.email = currentLinkman.email;
    linkman!.publicKey = currentLinkman.publicKey;
    linkman!.peerPublicKey = currentLinkman.peerPublicKey;
    linkman!.linkmanStatus = LinkmanStatus.chatGPT.name;
    linkman!.status ??= EntityStatus.effective.name;
    linkman!.startDate ??= DateUtil.currentDate();
    linkman!.endDate ??= DateUtil.maxDate();
    await linkmanService.store(linkman!);
    if (mounted) {
      DialogUtil.info(context,
          content:
              AppLocalizations.t('Create ChatGPT linkman is successfully'));
    }
    linkmanChatSummaryController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add chatGPT';
    int? id = linkman?.id;
    if (id != null) {
      title = 'Edit chatGPT';
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));

    return appBarView;
  }

  @override
  void dispose() {
    strangerController.removeListener(_update);
    super.dispose();
  }
}
