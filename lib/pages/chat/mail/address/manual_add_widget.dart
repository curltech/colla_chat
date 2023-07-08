import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/emailaddress.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';

/// 邮件地址手工注册组件，录入框和按钮组合
class ManualAddWidget extends StatefulWidget with TileDataMixin {
  const ManualAddWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ManualAddWidgetState();

  @override
  String get routeName => 'mail_address_manual_add';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.handyman;

  @override
  String get title => 'MailAddressManualAdd';
}

class _ManualAddWidgetState extends State<ManualAddWidget> {
  static const String imapServerPort = '993';
  static const String popServerPort = '995';
  static const String smtpServerPort = '465';

  List<ColumnFieldDef> _getManualDiscoveryColumnFieldDefs() {
    final List<ColumnFieldDef> manualDiscoveryColumnFieldDefs = [
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
      ColumnFieldDef(
        name: 'smtpServerHost',
        label: 'SmtpServerHost',
        prefixIcon: Icon(
          Icons.desktop_mac,
          color: myself.primary,
        ),
        initValue: 'smtp.163.com',
      ),
      ColumnFieldDef(
        name: 'smtpServerPort',
        label: 'SmtpServerPort',
        prefixIcon: Icon(
          Icons.router,
          color: myself.primary,
        ),
        initValue: smtpServerPort,
      ),
      ColumnFieldDef(
        name: 'imapServerHost',
        label: 'ImapServerHost',
        prefixIcon: Icon(
          Icons.desktop_mac,
          color: myself.primary,
        ),
        initValue: 'imap.163.com',
      ),
      ColumnFieldDef(
        name: 'imapServerPort',
        label: 'ImapServerPort',
        prefixIcon: Icon(
          Icons.router,
          color: myself.primary,
        ),
        initValue: imapServerPort,
      ),
      ColumnFieldDef(
        name: 'popServerHost',
        label: 'PopServerHost',
        prefixIcon: Icon(
          Icons.desktop_mac,
          color: myself.primary,
        ),
        initValue: 'pop.163.com',
      ),
      ColumnFieldDef(
        name: 'popServerPort',
        label: 'PopServerPort',
        prefixIcon: Icon(
          Icons.router,
          color: myself.primary,
        ),
        initValue: popServerPort,
      )
    ];

    return manualDiscoveryColumnFieldDefs;
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: 550,
          formButtonDefs: [
            FormButtonDef(
                label: 'Connect',
                onTap: (Map<String, dynamic> values) {
                  _connect(values);
                }),
          ],
          columnFieldDefs: _getManualDiscoveryColumnFieldDefs(),
        ));

    return formInputWidget;
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
    String? smtpServerHost = values['smtpServerHost'];
    String? smtpServerPort = values['smtpServerPort'];
    if (StringUtil.isEmpty(smtpServerHost) ||
        StringUtil.isEmpty(smtpServerPort)) {
      logger.e('smtpServerHost or smtpServerPort  is empty');
      if (mounted) {
        DialogUtil.error(context,
            content: 'smtpServerHost or smtpServerPort is empty');
      }
      return;
    }
    String? imapServerHost = values['imapServerHost'];
    String? imapServerPort = values['imapServerPort'];
    if (StringUtil.isEmpty(imapServerHost) ||
        StringUtil.isEmpty(imapServerPort)) {
      logger.e('imapServerHost or imapServerPort  is empty');
      if (mounted) {
        DialogUtil.error(context,
            content: 'imapServerHost or imapServerPort is empty');
      }
      return;
    }

    var emails = email!.split('@');
    String domain = emails[1];
    List<String?>? domains = [domain];
    String? displayName = domain;
    String? displayShortName = name;
    List<ServerConfig>? incomingServers = [
      ServerConfig(
        type: ServerType.imap,
        hostname: imapServerHost,
        port: int.parse(imapServerPort!),
        socketType: SocketType.ssl,
        authentication: Authentication.plain,
        usernameType: UsernameType.emailAddress,
      )
    ];
    String? popServerHost = values['popServerHost'];
    String? popServerPort = values['popServerPort'];
    if (StringUtil.isNotEmpty(popServerHost) ||
        StringUtil.isNotEmpty(popServerPort)) {
      incomingServers.add(ServerConfig(
        type: ServerType.pop,
        hostname: popServerHost,
        port: int.parse(popServerPort!),
        socketType: SocketType.ssl,
        authentication: Authentication.plain,
        usernameType: UsernameType.emailAddress,
      ));
    }
    List<ServerConfig>? outgoingServers = [
      ServerConfig(
        type: ServerType.smtp,
        hostname: smtpServerHost,
        port: int.parse(smtpServerPort!),
        socketType: SocketType.ssl,
        authentication: Authentication.plain,
        usernameType: UsernameType.emailAddress,
      )
    ];
    ConfigEmailProvider emailProviders = ConfigEmailProvider(
        domains: domains,
        displayName: displayName,
        displayShortName: displayShortName,
        incomingServers: incomingServers,
        outgoingServers: outgoingServers);
    ClientConfig clientConfig = ClientConfig(emailProviders: [emailProviders]);
    var mailAddress =
        EmailMessageUtil.buildDiscoverMailAddress(email, name!, clientConfig);
    DialogUtil.loadingShow(context,
        tip: 'Manual connecting email server,\n please waiting...');
    EmailClient? emailClient = await emailClientPool
        .create(mailAddress, password!, config: clientConfig);
    if (mounted) {
      DialogUtil.loadingHide(context);
    }
    if (emailClient == null) {
      logger.e('Connect fail to $name.');
      if (mounted) {
        DialogUtil.info(context, content: 'Connect failure');
      }
      return;
    }
    if (mounted) {
      DialogUtil.info(context, content: 'Connect successfully');
    }
    logger.i('create (or connect) success to $name.');
    EmailAddress? emailAddress =
        await emailAddressService.findByMailAddress(email);
    if (emailAddress == null && mounted) {
      bool? result =
          await DialogUtil.confirm(context, content: 'Save new mail address?');

      if (result != null && result) {
        ///保存地址
        await emailAddressService.store(mailAddress);
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
