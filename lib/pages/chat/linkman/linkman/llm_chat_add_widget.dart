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
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//联系人信息页面
class LlmChatAddWidget extends StatelessWidget with DataTileMixin {
  LlmChatAddWidget({super.key}) {
    linkman ??= linkmanController.current;
  }

  @override
  String get routeName => 'llm_chat_add';

  @override
  bool get withLeading => true;

  @override
  dynamic get iconData => ImageUtil.buildImageWidget(
      imageContent: 'assets/image/ollama.png',
      width: AppIconSize.smSize,
      height: AppIconSize.smSize);

  @override
  String get title => 'Add llm linkman';

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

  late final PlatformReactiveFormController platformReactiveFormController =
      PlatformReactiveFormController(llmChatDataFields);
  Linkman? linkman;

  Widget _buildPlatformReactiveForm(BuildContext context) {
    return Obx(() {
      Linkman? linkman = linkmanController.current;
      if (linkman != null) {
        platformReactiveFormController.values = JsonUtil.toJson(linkman);
      }

      var formInputWidget = Container(
          padding: const EdgeInsets.all(15.0),
          child: PlatformReactiveForm(
            height: 420,
            onSubmit: (Map<String, dynamic> values) {
              _onOk(context, values);
            },
            platformReactiveFormController: platformReactiveFormController,
          ));

      return ListView(children: [formInputWidget]);
    });
  }

  Future<void> _onOk(BuildContext context, Map<String, dynamic> values) async {
    if (values['name'] == null) {
      DialogUtil.error(content: AppLocalizations.t('Must have name'));
      return;
    }
    if (values['peerId'] == null) {
      DialogUtil.error(content: AppLocalizations.t('Must have url address'));
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
    DialogUtil.info(
        content: AppLocalizations.t('Create Llm linkman is successfully'));
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
        helpPath: routeName,
        withLeading: withLeading,
        child: _buildPlatformReactiveForm(context));

    return appBarView;
  }
}
