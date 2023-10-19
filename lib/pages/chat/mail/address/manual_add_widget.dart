import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/pages/chat/mail/address/email_service_provider.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/emailaddress.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
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
  late final FormInputController controller;

  static const String imapServerPort = '993';
  static const String popServerPort = '995';
  static const String smtpServerPort = '465';

  @override
  initState() {
    super.initState();
    controller = FormInputController(_getManualDiscoveryColumnFieldDefs());
  }

  List<PlatformDataField> _getManualDiscoveryColumnFieldDefs() {
    final List<PlatformDataField> manualDiscoveryColumnFieldDefs = [
      PlatformDataField(
          name: 'name',
          label: 'Name',
          prefixIcon: Icon(
            Icons.person,
            color: myself.primary,
          )),
      PlatformDataField(
        name: 'email',
        label: 'Email',
        prefixIcon: Icon(
          Icons.email,
          color: myself.primary,
        ),
        textInputType: TextInputType.emailAddress,
      ),
      PlatformDataField(
          name: 'password',
          label: 'Password',
          prefixIcon: Icon(
            Icons.password,
            color: myself.primary,
          ),
          inputType: InputType.password),
      PlatformDataField(
        name: 'smtpServerHost',
        label: 'SmtpServerHost',
        prefixIcon: Icon(
          Icons.desktop_mac,
          color: myself.primary,
        ),
        initValue: 'smtp.163.com',
      ),
      PlatformDataField(
        name: 'smtpServerPort',
        label: 'SmtpServerPort',
        prefixIcon: Icon(
          Icons.router,
          color: myself.primary,
        ),
        initValue: smtpServerPort,
      ),
      PlatformDataField(
        name: 'imapServerHost',
        label: 'ImapServerHost',
        prefixIcon: Icon(
          Icons.desktop_mac,
          color: myself.primary,
        ),
        initValue: 'imap.163.com',
      ),
      PlatformDataField(
        name: 'imapServerPort',
        label: 'ImapServerPort',
        prefixIcon: Icon(
          Icons.router,
          color: myself.primary,
        ),
        initValue: imapServerPort,
      ),
      PlatformDataField(
        name: 'popServerHost',
        label: 'PopServerHost',
        prefixIcon: Icon(
          Icons.desktop_mac,
          color: myself.primary,
        ),
        initValue: 'pop.163.com',
      ),
      PlatformDataField(
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
    double height = appDataProvider.portraitSize.height * 0.7;
    var formInputWidget = SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(children: [
              const SizedBox(height: 10.0),
              FormInputWidget(
                height: height,
                spacing: 5.0,
                formButtons: [
                  FormButton(
                      label: 'Connect',
                      onTap: (Map<String, dynamic> values) {
                        _connect(values);
                      }),
                ],
                controller: controller,
              )
            ])));

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
    var emails = email!.split('@');
    EmailServiceProvider? emailServiceProvider;
    String domain = emails[1];
    if (platformEmailServiceProvider.domainNameServiceProviders
        .containsKey(domain)) {
      emailServiceProvider =
          platformEmailServiceProvider.domainNameServiceProviders[domain];
    } else {
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
      String? displayName = domain;
      String? displayShortName = name;
      ServerConfig imapServerConfig = ServerConfig(
        type: ServerType.imap,
        hostname: imapServerHost,
        port: int.parse(imapServerPort!),
        socketType: SocketType.ssl,
        authentication: Authentication.plain,
        usernameType: UsernameType.emailAddress,
      );
      String? popServerHost = values['popServerHost'];
      String? popServerPort = values['popServerPort'];
      ServerConfig? popServerConfig;
      if (StringUtil.isNotEmpty(popServerHost) ||
          StringUtil.isNotEmpty(popServerPort)) {
        popServerConfig = ServerConfig(
          type: ServerType.pop,
          hostname: popServerHost,
          port: int.parse(popServerPort!),
          socketType: SocketType.ssl,
          authentication: Authentication.plain,
          usernameType: UsernameType.emailAddress,
        );
      }
      ServerConfig smtpServerConfig = ServerConfig(
        type: ServerType.smtp,
        hostname: smtpServerHost,
        port: int.parse(smtpServerPort!),
        socketType: SocketType.ssl,
        authentication: Authentication.plain,
        usernameType: UsernameType.emailAddress,
      );
      ClientConfig clientConfig = ClientConfig();
      ConfigEmailProvider configEmailProvider = ConfigEmailProvider(
        displayName: displayName,
        displayShortName: displayShortName,
      );
      configEmailProvider.addIncomingServer(imapServerConfig);
      if (popServerConfig != null) {
        configEmailProvider.addIncomingServer(popServerConfig);
      }
      configEmailProvider.addOutgoingServer(smtpServerConfig);
      clientConfig.addEmailProvider(configEmailProvider);

      emailServiceProvider =
          EmailServiceProvider(domain, imapServerHost!, clientConfig);
    }

    EmailAddress emailAddress = EmailMessageUtil.buildDiscoverEmailAddress(
        email, name!, emailServiceProvider!.clientConfig);
    DialogUtil.loadingShow(context,
        tip: 'Manual connecting email server,\n please waiting...');
    EmailClient? emailClient = await emailClientPool.create(
        emailAddress, password!,
        config: emailServiceProvider.clientConfig);
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
    if (mounted) {
      bool? result =
          await DialogUtil.confirm(context, content: 'Save new mail address?');
      if (result != null && result) {
        EmailAddress? old = await emailAddressService.findByMailAddress(email);
        if (old != null) {
          emailAddress.id = old.id;
          emailAddress.createDate = old.createDate;
        }
        emailAddress.name = name;
        emailAddress.password = password;

        ///保存地址
        await emailAddressService.store(emailAddress);
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
