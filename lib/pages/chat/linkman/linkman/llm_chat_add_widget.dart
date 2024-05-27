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
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

//联系人信息页面
class LlmChatAddWidget extends StatefulWidget with TileDataMixin {
  const LlmChatAddWidget({super.key});

  @override
  State<StatefulWidget> createState() => _LlmChatAddWidgetState();

  @override
  String get routeName => 'llm_chat_add';

  @override
  bool get withLeading => true;

  @override
  dynamic get iconData => ImageUtil.buildImageWidget(
      image: 'assets/images/ollama.png',
      width: AppIconSize.smSize,
      height: AppIconSize.smSize);

  @override
  String get title => 'Add llm linkman';
}

class _LlmChatAddWidgetState extends State<LlmChatAddWidget> {
  final List<PlatformDataField> llmChatDataFields = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'peerId',
        label: 'Url',
        prefixIcon: Icon(
          Icons.web,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(
          Icons.person,
          color: myself.primary,
        )),
  ];

  late final FormInputController controller =
      FormInputController(llmChatDataFields);
  Linkman? linkman;

  @override
  initState() {
    super.initState();
    linkmanController.addListener(_update);
    linkman ??= linkmanController.current;
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    Linkman? linkman = linkmanController.current;
    if (linkman != null) {
      controller.setValues(JsonUtil.toJson(linkman));
    }

    var formInputWidget = Container(
        padding: const EdgeInsets.all(15.0),
        child: FormInputWidget(
          height: 420,
          onOk: (Map<String, dynamic> values) {
            _onOk(values);
          },
          controller: controller,
        ));

    return ListView(children: [formInputWidget]);
  }

  _onOk(Map<String, dynamic> values) async {
    if (values['name'] == null) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must have name'));
      return;
    }
    if (values['peerId'] == null) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must have url address'));
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
    linkman!.linkmanStatus = LinkmanStatus.G.name;
    linkman!.status ??= EntityStatus.effective.name;
    linkman!.startDate ??= DateUtil.currentDate();
    linkman!.endDate ??= DateUtil.maxDate();
    await linkmanService.store(linkman!);
    if (mounted) {
      DialogUtil.info(context,
          content:
              AppLocalizations.t('Create Llm linkman is successfully'));
    }
    linkmanChatSummaryController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add Llm linkman';
    int? id = linkman?.id;
    if (id != null) {
      title = 'Edit Llm linkman';
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));

    return appBarView;
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
