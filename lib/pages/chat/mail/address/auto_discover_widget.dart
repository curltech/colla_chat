import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/mailaddress.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
  ValueNotifier<ClientConfig?> clientConfig =
      ValueNotifier<ClientConfig?>(null);

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
          initValue: 'GRDCGOUASMNEBSTH',
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
          height: 250,
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
    String? email = values['email'];
    if (StringUtil.isEmpty(email)) {
      if (mounted) {
        DialogUtil.error(context, content: 'Email is empty');
      }
      return;
    }
    try {
      DialogUtil.loadingShow(context,
          tip: 'Auto discovering email server, please waiting...');
      ClientConfig? clientConfig = await EmailMessageUtil.discover(email!);
      if (mounted) {
        DialogUtil.loadingHide(context);
      }
      if (clientConfig != null) {
        if (mounted) {
          DialogUtil.info(context, content: 'Auto discover successfully');
        }
        this.clientConfig.value = clientConfig;
      } else {
        if (mounted) {
          DialogUtil.error(context, content: 'Auto discover failure');
        }
      }
    } catch (e) {
      logger.e('Auto discover failure:$e');
      if (mounted) {
        DialogUtil.error(context, content: 'Auto discover failure');
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
        DialogUtil.error(context, content: 'Email or name is empty');
      }
      return;
    }
    var clientConfig = this.clientConfig.value;
    if (clientConfig == null) {
      logger.e('auto discover config is null');
      if (mounted) {
        DialogUtil.error(context, content: 'Auto discovery config is null');
      }
      return;
    }
    var mailAddress =
        EmailMessageUtil.buildDiscoverMailAddress(email!, name!, clientConfig);
    DialogUtil.loadingShow(context,
        tip: 'Auto connecting email server, please waiting...');
    EmailClient? emailClient = await emailClientPool
        .create(mailAddress, password!, config: clientConfig);
    if (mounted) {
      DialogUtil.loadingHide(context);
    }
    if (emailClient == null) {
      logger.e('create (or connect) fail to $name.');
      return;
    }
    logger.i('create (or connect) success to $name.');
    if (mounted) {
      bool? result =
          await DialogUtil.confirm(context, content: 'Save mail address?');

      if (result != null && result) {
        ///保存地址
        await mailAddressService.store(mailAddress);
      }
    }
  }

  static List<Widget> clientConfigWidget(ClientConfig clientConfig) {
    List<Widget> configWidgets = [];
    for (final ConfigEmailProvider provider in clientConfig.emailProviders!) {
      configWidgets
          .add(CommonAutoSizeText('displayName:${provider.displayName ?? ''}'));
      configWidgets
          .add(CommonAutoSizeText('domains:${provider.domains.toString()}'));
      configWidgets.add(const CommonAutoSizeText('preferredIncomingServer:'));
      configWidgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child:
              CommonAutoSizeText(provider.preferredIncomingServer.toString())));
      configWidgets.add(const CommonAutoSizeText('preferredOutgoingServer:'));
      configWidgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child:
              CommonAutoSizeText(provider.preferredOutgoingServer.toString())));
    }
    return configWidgets;
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: Column(children: [
          _buildFormInputWidget(context),
          Expanded(
              child: ValueListenableBuilder(
                  valueListenable: clientConfig,
                  builder: (BuildContext context, ClientConfig? clientConfig,
                      Widget? child) {
                    if (clientConfig != null) {
                      return Card(
                          elevation: 0.0,
                          margin: EdgeInsets.zero,
                          shape: const ContinuousRectangleBorder(),
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 15.0),
                              child: ListView(
                                children: clientConfigWidget(clientConfig),
                              )));
                    }
                    return Container();
                  }))
        ]));

    return appBarView;
  }
}
