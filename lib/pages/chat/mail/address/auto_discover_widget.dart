import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/pages/chat/mail/address/email_service_provider.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/emailaddress.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/emailclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
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
  ValueNotifier<EmailServiceProvider?> emailServiceProvider =
      ValueNotifier<EmailServiceProvider?>(null);
  TextEditingController emailServiceProviderController =
      TextEditingController();
  ValueNotifier<List<Option<String>>> emailServiceProviderOptions =
      ValueNotifier<List<Option<String>>>([]);

  @override
  void initState() {
    super.initState();
    _updateEmailServiceProviderOptions();
  }

  _updateEmailServiceProviderOptions() {
    List<Option<String>> items = [];
    for (var emailServiceProvider
        in platformEmailServiceProvider.emailServiceProviders) {
      items.add(Option(
          emailServiceProvider.domainName, emailServiceProvider.domainName,
          leading: emailServiceProvider.logo,
          checked: emailServiceProviderController.text ==
              emailServiceProvider.domainName,
          hint: emailServiceProvider.incomingHostName));
    }
    emailServiceProviderOptions.value = items;
  }

  Widget _buildEmailServiceProviderSelector(BuildContext context) {
    Widget emailServiceProvider = ValueListenableBuilder(
        valueListenable: emailServiceProviderOptions,
        builder: (BuildContext buildContext, List<Option<String>> options,
            Widget? child) {
          Widget? prefix;
          for (var option in options) {
            if (option.checked && option.leading != null) {
              prefix = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: option.leading);
              break;
            }
          }
          return CommonAutoSizeTextFormField(
            labelText: 'Select email service provider',
            prefixIcon: prefix,
            controller: emailServiceProviderController,
            readOnly: true,
            suffixIcon: IconButton(
              onPressed: () async {
                String? domainName = await DialogUtil.showSelectDialog<String>(
                    context: context,
                    title: const CommonAutoSizeText(
                        'Select email service provider'),
                    items: options);
                if (domainName != null) {
                  emailServiceProviderController.text = domainName;
                  _updateEmailServiceProviderOptions();
                }
              },
              icon: Icon(
                Icons.search,
                color: myself.primary,
              ),
            ),
          );
        });

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: emailServiceProvider);
  }

  List<ColumnFieldDef> _getAutoDiscoveryColumnFieldDefs() {
    final List<ColumnFieldDef> autoDiscoveryColumnFieldDefs = [
      ColumnFieldDef(
          name: 'name',
          label: 'Name',
          prefixIcon: Icon(
            Icons.person,
            color: myself.primary,
          )),
      ColumnFieldDef(
        name: 'email',
        label: 'Email',
        prefixIcon: Icon(
          Icons.email,
          color: myself.primary,
        ),
        textInputType: TextInputType.emailAddress,
      ),
      ColumnFieldDef(
          name: 'password',
          label: 'Password',
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
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: FormInputWidget(
          height: 250,
          spacing: 5.0,
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

    DialogUtil.loadingShow(context,
        tip: 'Auto discovering email server,\n please waiting...');
    try {
      EmailServiceProvider? emailServiceProvider =
          await EmailMessageUtil.discover(email!);
      if (emailServiceProvider != null) {
        if (mounted) {
          DialogUtil.info(context, content: 'Auto discover successfully');
        }
        this.emailServiceProvider.value = emailServiceProvider;
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
    if (mounted) {
      DialogUtil.loadingHide(context);
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
    var emailServiceProvider = this.emailServiceProvider.value;
    if (emailServiceProvider == null) {
      EmailServiceProvider? emailServiceProvider =
          await EmailMessageUtil.discover(email!);
      if (emailServiceProvider == null) {
        logger.e('auto discover emailServiceProvider is null');
        if (mounted) {
          DialogUtil.error(context,
              content: 'Auto discovery emailServiceProvider is null');
        }
        return;
      }
    }
    ClientConfig clientConfig = emailServiceProvider!.clientConfig;
    EmailAddress emailAddress =
        EmailMessageUtil.buildDiscoverEmailAddress(email!, name!, clientConfig);
    if (mounted) {
      DialogUtil.loadingShow(context,
          tip: 'Auto connecting email server,\n please waiting...');
    }
    EmailClient? emailClient = await emailClientPool
        .create(emailAddress, password!, config: clientConfig);
    if (mounted) {
      DialogUtil.loadingHide(context);
    }
    if (emailClient == null) {
      logger.e('create (or connect) fail to $name.');
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

  List<Widget> clientConfigWidget(ClientConfig clientConfig) {
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
          const SizedBox(
            height: 10.0,
          ),
          //_buildEmailServiceProviderSelector(context),
          _buildFormInputWidget(context),
          Expanded(
              child: ValueListenableBuilder(
                  valueListenable: emailServiceProvider,
                  builder: (BuildContext context,
                      EmailServiceProvider? emailServiceProvider,
                      Widget? child) {
                    if (emailServiceProvider != null) {
                      return Card(
                          elevation: 0.0,
                          margin: EdgeInsets.zero,
                          shape: const ContinuousRectangleBorder(),
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 15.0),
                              child: ListView(
                                children: clientConfigWidget(
                                    emailServiceProvider.clientConfig),
                              )));
                    }
                    return Container();
                  }))
        ]));

    return appBarView;
  }
}
