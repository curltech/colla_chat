import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/mailaddress.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:enough_mail/discover.dart';
import 'package:flutter/material.dart';

/// 自动邮件发现视图，一个card下的录入框和按钮组合
class AutoDiscoverWidget extends StatefulWidget with TileDataMixin {
  const AutoDiscoverWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AutoDiscoverWidgetState();

  @override
  String get routeName => 'mail_address_auto_discover';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.auto_mode;

  @override
  String get title => 'MailAddressAutoDiscover';
}

class _AutoDiscoverWidgetState extends State<AutoDiscoverWidget> {
  ClientConfig? config;

  @override
  void initState() {
    super.initState();
  }

  List<ColumnFieldDef> _getAutoDiscoveryColumnFieldDefs() {
    final List<ColumnFieldDef> autoDiscoveryColumnFieldDefs = [
      ColumnFieldDef(
          name: 'name',
          label: 'Name',
          initValue: '胡劲松',
          prefixIcon: Icon(
            Icons.person,
            color: myself.primary,
          )),
      ColumnFieldDef(
        name: 'email',
        label: 'Email',
        initValue: 'hujs06@163.com',
        prefixIcon: Icon(
          Icons.email,
          color: myself.primary,
        ),
        textInputType: TextInputType.emailAddress,
      ),
      ColumnFieldDef(
          name: 'password',
          label: 'Password',
          initValue: 'OZJBOVNGLGCWAZZX',
          prefixIcon: Icon(
            Icons.password,
            color: myself.primary,
          ),
          inputType: InputType.password),
    ];

    return autoDiscoveryColumnFieldDefs;
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: 330,
          formButtonDefs: [
            FormButtonDef(
                label: 'Discover',
                onTap: (Map<String, dynamic> values) {
                  _discover(values);
                }),
            FormButtonDef(
                label: 'Connect',
                onTap: (Map<String, dynamic> values) {
                  _connect(values);
                }),
          ],
          columnFieldDefs: _getAutoDiscoveryColumnFieldDefs(),
        ));

    return formInputWidget;
  }

  Future<void> _discover(Map<String, dynamic> values) async {
    String? name = values['name'];
    String? email = values['email'];
    if (StringUtil.isEmpty(email) || StringUtil.isEmpty(name)) {
      logger.e('email or name is empty');
      if (mounted) {
        DialogUtil.error(context, content: 'email or name is empty');
      }
      return;
    }
    ClientConfig? config = await EmailMessageUtil.discover(email!);
    if (config != null) {
      if (mounted) {
        DialogUtil.info(context, content: 'auto discover successfully');
      }
      this.config = config;
    } else {
      if (mounted) {
        DialogUtil.error(context, content: 'auto discover failure');
      }
    }
  }

  _connect(Map<String, dynamic> values) async {
    String? name = values['name'];
    String? email = values['email'];
    String? password = values['password'];
    if (StringUtil.isEmpty(email) ||
        StringUtil.isEmpty(name) ||
        StringUtil.isEmpty(password)) {
      logger.e('email or name or password is empty');
      if (mounted) {
        DialogUtil.error(context, content: 'email or name is empty');
      }
      return;
    }
    var config = this.config;
    if (config == null) {
      logger.e('auto discover config is null');
      if (mounted) {
        DialogUtil.error(context, content: 'auto dicover config is null');
      }
      return;
    }
    var mailAddress =
        EmailMessageUtil.buildDiscoverMailAddress(email!, name!, config);
    EmailClient? emailClient = await EmailClientPool.instance
        .create(mailAddress, password!, config: this.config);
    if (emailClient == null) {
      logger.e('create (or connect) fail to $name.');
      return;
    }
    logger.i('create (or connect) success to $name.');
    if (mounted) {
      bool? result = await DialogUtil.confirm(context, content: '保存为地址吗?');

      if (result != null && result) {
        ///保存地址
        await mailAddressService.store(mailAddress);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));

    return appBarView;
  }
}
