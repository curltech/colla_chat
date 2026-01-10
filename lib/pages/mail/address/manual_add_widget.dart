import 'package:colla_chat/entity/mail/mail_address.dart';
import 'package:colla_chat/pages/mail/address/email_service_provider.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/mail/mail_address.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;
import 'package:flutter/material.dart';

/// 邮件地址手工注册组件，录入框和按钮组合
class ManualAddWidget extends StatelessWidget with TileDataMixin {
  ManualAddWidget({super.key});

  @override
  String get routeName => 'mail_address_manual_add';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.handyman;

  @override
  String get title => 'MailAddressManualAdd';

  late final PlatformReactiveFormController platformReactiveFormController =
      PlatformReactiveFormController(_getManualDiscoveryColumnField());

  static const String imapServerPort = '993';
  static const String popServerPort = '995';
  static const String smtpServerPort = '465';

  List<PlatformDataField> _getManualDiscoveryColumnField() {
    final List<PlatformDataField> manualDiscoveryColumnField = [
      PlatformDataField(
          name: 'id',
          label: 'Id',
          readOnly: true,
          prefixIcon: Icon(
            Icons.numbers_outlined,
            color: myself.primary,
          )),
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

    return manualDiscoveryColumnField;
  }

  Widget _buildPlatformReactiveForm(BuildContext context) {
    double height = appDataProvider.portraitSize.height * 0.7;
    var platformReactiveForm = SingleChildScrollView(
        child: Column(children: [
      const SizedBox(height: 10.0),
      PlatformReactiveForm(
        height: height,
        spacing: 5.0,
        formButtons: [
          FormButton(
              label: 'Connect',
              onTap: (Map<String, dynamic> values) {
                _connect(values);
              }),
        ],
        platformReactiveFormController: platformReactiveFormController,
      )
    ]));

    return platformReactiveForm;
  }

  Future<void> _connect(Map<String, dynamic> values) async {
    String? name = values['name'];
    String? email = values['email'];
    String? password = values['password'];
    if (StringUtil.isEmpty(email) ||
        StringUtil.isEmpty(name) ||
        StringUtil.isEmpty(password)) {
      logger.e('email or name or password is empty');
      DialogUtil.error(content: 'Email or name is empty');
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
      String smtpServerHost = values['smtpServerHost'];
      String? smtpServerPort = values['smtpServerPort'];
      if (StringUtil.isEmpty(smtpServerHost) ||
          StringUtil.isEmpty(smtpServerPort)) {
        logger.e('smtpServerHost or smtpServerPort  is empty');
        DialogUtil.error(content: 'smtpServerHost or smtpServerPort is empty');
        return;
      }
      String imapServerHost = values['imapServerHost']!;
      String? imapServerPort = values['imapServerPort'];
      if (StringUtil.isEmpty(imapServerHost) ||
          StringUtil.isEmpty(imapServerPort)) {
        logger.e('imapServerHost or imapServerPort  is empty');
        DialogUtil.error(content: 'imapServerHost or imapServerPort is empty');
        return;
      }
      String? displayName = domain;
      String? displayShortName = name;
      enough_mail.ServerConfig imapServerConfig = enough_mail.ServerConfig(
        type: enough_mail.ServerType.imap,
        hostname: imapServerHost,
        port: int.parse(imapServerPort!),
        socketType: enough_mail.SocketType.ssl,
        authentication: enough_mail.Authentication.plain,
        usernameType: enough_mail.UsernameType.emailAddress,
      );
      String popServerHost = values['popServerHost']!;
      String? popServerPort = values['popServerPort'];
      enough_mail.ServerConfig? popServerConfig;
      if (StringUtil.isNotEmpty(popServerHost) ||
          StringUtil.isNotEmpty(popServerPort)) {
        popServerConfig = enough_mail.ServerConfig(
          type: enough_mail.ServerType.pop,
          hostname: popServerHost,
          port: int.parse(popServerPort!),
          socketType: enough_mail.SocketType.ssl,
          authentication: enough_mail.Authentication.plain,
          usernameType: enough_mail.UsernameType.emailAddress,
        );
      }
      enough_mail.ServerConfig smtpServerConfig = enough_mail.ServerConfig(
        type: enough_mail.ServerType.smtp,
        hostname: smtpServerHost,
        port: int.parse(smtpServerPort!),
        socketType: enough_mail.SocketType.ssl,
        authentication: enough_mail.Authentication.plain,
        usernameType: enough_mail.UsernameType.emailAddress,
      );
      enough_mail.ClientConfig clientConfig = enough_mail.ClientConfig();
      enough_mail.ConfigEmailProvider configEmailProvider =
          enough_mail.ConfigEmailProvider(
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
          EmailServiceProvider(domain, imapServerHost, clientConfig);
    }

    MailAddress emailAddress = EmailMessageUtil.buildDiscoverEmailAddress(
        email, name!, emailServiceProvider!.clientConfig);
    DialogUtil.loadingShow(
        tip: 'Manual connecting email server,\n please waiting...');
    EmailClient? emailClient = await emailClientPool.create(
        emailAddress, password!,
        config: emailServiceProvider.clientConfig);
    DialogUtil.loadingHide();
    if (emailClient == null) {
      logger.e('Connect fail to $name.');
      DialogUtil.info(content: 'Connect failure');
      return;
    }
    DialogUtil.info(content: 'Connect successfully');
    logger.i('create (or connect) success to $name.');
    bool? result = await DialogUtil.confirm(content: 'Save new mail address?');
    if (result != null && result) {
      MailAddress? old = await mailAddressService.findByMailAddress(email);
      emailAddress.id = old?.id;
      emailAddress.createDate = old?.createDate;
      emailAddress.name = name;
      emailAddress.password = password;

      ///保存地址
      await mailAddressService.store(emailAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: withLeading,
        child: _buildPlatformReactiveForm(context));

    return appBarView;
  }
}
