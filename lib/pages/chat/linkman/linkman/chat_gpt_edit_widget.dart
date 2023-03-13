import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> chatGPTColumnFieldDefs = [
  ColumnFieldDef(
      name: 'peerId',
      label: 'apiKey',
      inputType: InputType.label,
      prefixIcon: const Icon(Icons.key)),
  ColumnFieldDef(
      name: 'name', label: 'Name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'alias', label: 'Alias', prefixIcon: const Icon(Icons.person_pin)),
  ColumnFieldDef(
      name: 'email',
      label: 'Email',
      prefixIcon: const Icon(Icons.email),
      inputType: InputType.text),
  ColumnFieldDef(
      name: 'clientId',
      label: 'password',
      inputType: InputType.password,
      prefixIcon: const Icon(Icons.password)),
];

//联系人信息页面
class ChatGPTEditWidget extends StatefulWidget with TileDataMixin {
  const ChatGPTEditWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatGPTEditWidgetState();

  @override
  String get routeName => 'chat_gpt_edit';

  @override
  bool get withLeading => true;

  @override
  dynamic get iconData =>
      ImageUtil.buildImageWidget(image: 'assets/images/openai.png');

  @override
  String get title => 'ChatGPT edit';
}

class _ChatGPTEditWidgetState extends State<ChatGPTEditWidget> {
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
    Map<String, dynamic>? initValues =
        linkmanController.getInitValue(chatGPTColumnFieldDefs);

    var formInputWidget = Container(
        padding: const EdgeInsets.all(15.0),
        child: FormInputWidget(
          onOk: (Map<String, dynamic> values) {
            _onOk(values);
          },
          columnFieldDefs: chatGPTColumnFieldDefs,
          initValues: initValues,
        ));

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    Linkman currentLinkman = Linkman.fromJson(values);
    linkman!.peerId = currentLinkman.peerId;
    linkman!.name = currentLinkman.name;
    linkman!.alias = currentLinkman.alias;
    linkman!.mobile = currentLinkman.mobile;
    linkman!.email = currentLinkman.email;
    linkman!.clientId = currentLinkman.clientId;
    linkman!.linkmanStatus = LinkmanStatus.chatGPT.name;
    await linkmanService.store(linkman!);
    linkmanChatSummaryController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: SingleChildScrollView(child: _buildFormInputWidget(context)));
    return appBarView;
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
