import 'package:colla_chat/pages/chat/mail/address/oauth.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:enough_mail/discover.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final Map<String, EmailServiceProvider> emailServiceProviders =
    <String, EmailServiceProvider>{
  'gmail': GmailProvider(),
  'outlook': OutlookProvider(),
  'yahoo': YahooProvider(),
  'aol': AolProvider(),
  'apple': AppleProvider(),
  'gmx': GmxProvider(),
  'mailbox': MailboxOrgProvider(),
};

Future<EmailServiceProvider?> discover(String email) async {
  final emailDomain = email.substring(email.indexOf('@') + 1);
  final providerEmail = emailServiceProviders[emailDomain];
  if (providerEmail != null) {
    return providerEmail;
  }
  try {
    final clientConfig = await Discover.discover(email,
        forceSslConnection: true, isLogEnabled: true);
    if (clientConfig == null || clientConfig.preferredIncomingServer == null) {
      return null;
    }
    final hostName = clientConfig.preferredIncomingServer!.hostname!;
    final providerHostName = emailServiceProviders[hostName];
    if (providerHostName != null) {
      return providerHostName;
    }
    final id = email.substring(email.indexOf('@') + 1);
    return EmailServiceProvider(id, hostName, clientConfig);
  } catch (e, s) {
    if (kDebugMode) {
      print('Unable to discover settings for [$email]: $e $s');
    }
    return null;
  }
}

class EmailServiceProvider {
  final String name; //邮件服务商提供者
  final String incomingHostName; //imap主机名
  final ClientConfig clientConfig; //客户端配置
  Widget? logo;

  final OauthClient? oauthClient; //oauth验证客户端
  final String? appSpecificPasswordSetupUrl;
  final String? manualImapAccessSetupUrl;
  final List<String>? domains;

  String? get displayName => (clientConfig.emailProviders == null ||
          clientConfig.emailProviders!.isEmpty)
      ? null
      : clientConfig.emailProviders!.first.displayName;

  EmailServiceProvider(
    this.name,
    this.incomingHostName,
    this.clientConfig, {
    this.oauthClient,
    this.appSpecificPasswordSetupUrl,
    this.manualImapAccessSetupUrl,
    this.domains,
  }) {
    logo = ImageUtil.buildImageWidget(
        image: 'assets/images/providers/$name.png', height: 50);
  }
}

class GmailProvider extends EmailServiceProvider {
  GmailProvider()
      : super(
          'gmail',
          'imap.gmail.com',
          ClientConfig()
            ..emailProviders = [
              ConfigEmailProvider(
                displayName: 'Google Mail',
                displayShortName: 'Gmail',
                incomingServers: [
                  ServerConfig(
                    type: ServerType.imap,
                    hostname: 'imap.gmail.com',
                    port: 993,
                    socketType: SocketType.ssl,
                    authentication: Authentication.oauth2,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
                outgoingServers: [
                  ServerConfig(
                    type: ServerType.smtp,
                    hostname: 'smtp.gmail.com',
                    port: 465,
                    socketType: SocketType.ssl,
                    authentication: Authentication.oauth2,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
              )
            ],
          appSpecificPasswordSetupUrl:
              'https://support.google.com/accounts/answer/185833',
          domains: ['gmail.com', 'googlemail.com', 'google.com', 'jazztel.es'],
          oauthClient: GmailOAuthClient(),
        );
}

class OutlookProvider extends EmailServiceProvider {
  OutlookProvider()
      : super(
          'outlook',
          'outlook.office365.com',
          ClientConfig()
            ..emailProviders = [
              ConfigEmailProvider(
                displayName: 'Outlook.com',
                displayShortName: 'Outlook',
                incomingServers: [
                  ServerConfig(
                    type: ServerType.imap,
                    hostname: 'outlook.office365.com',
                    port: 993,
                    socketType: SocketType.ssl,
                    authentication: Authentication.oauth2,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
                outgoingServers: [
                  ServerConfig(
                    type: ServerType.smtp,
                    hostname: 'smtp.office365.com',
                    port: 587,
                    socketType: SocketType.starttls,
                    authentication: Authentication.oauth2,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
              )
            ],
          oauthClient: OutlookOAuthClient(),
          appSpecificPasswordSetupUrl:
              'https://support.microsoft.com/account-billing/using-app-passwords-with-apps-that-don-t-support-two-step-verification-5896ed9b-4263-e681-128a-a6f2979a7944',
          domains: [
            'hotmail.com',
            'live.com',
            'msn.com',
            'windowslive.com',
            'outlook.at',
            'outlook.be',
            'outlook.cl',
            'outlook.cz',
            'outlook.de',
            'outlook.dk',
            'outlook.es',
            'outlook.fr',
            'outlook.hu',
            'outlook.ie',
            'outlook.in',
            'outlook.it',
            'outlook.jp',
            'outlook.kr',
            'outlook.lv',
            'outlook.my',
            'outlook.ph',
            'outlook.pt',
            'outlook.sa',
            'outlook.sg',
            'outlook.sk',
            'outlook.co.id',
            'outlook.co.il',
            'outlook.co.th',
            'outlook.com.ar',
            'outlook.com.au',
            'outlook.com.br',
            'outlook.com.gr',
            'outlook.com.tr',
            'outlook.com.vn',
            'hotmail.be',
            'hotmail.ca',
            'hotmail.cl',
            'hotmail.cz',
            'hotmail.de',
            'hotmail.dk',
            'hotmail.es',
            'hotmail.fi',
            'hotmail.fr',
            'hotmail.gr',
            'hotmail.hu',
            'hotmail.it',
            'hotmail.lt',
            'hotmail.lv',
            'hotmail.my',
            'hotmail.nl',
            'hotmail.no',
            'hotmail.ph',
            'hotmail.rs',
            'hotmail.se',
            'hotmail.sg',
            'hotmail.sk',
            'hotmail.co.id',
            'hotmail.co.il',
            'hotmail.co.in',
            'hotmail.co.jp',
            'hotmail.co.kr',
            'hotmail.co.th',
            'hotmail.co.uk',
            'hotmail.co.za',
            'hotmail.com.ar',
            'hotmail.com.au',
            'hotmail.com.br',
            'hotmail.com.hk',
            'hotmail.com.tr',
            'hotmail.com.tw',
            'hotmail.com.vn',
            'live.at',
            'live.be',
            'live.ca',
            'live.cl',
            'live.cn',
            'live.de',
            'live.dk',
            'live.fi',
            'live.fr',
            'live.hk',
            'live.ie',
            'live.in',
            'live.it',
            'live.jp',
            'live.nl',
            'live.no',
            'live.ru',
            'live.se',
            'live.co.jp',
            'live.co.kr',
            'live.co.uk',
            'live.co.za',
            'live.com.ar',
            'live.com.au',
            'live.com.mx',
            'live.com.my',
            'live.com.ph',
            'live.com.pt',
            'live.com.sg',
            'livemail.tw',
            'olc.protection.outlook.com'
          ],
        );
}

class YahooProvider extends EmailServiceProvider {
  YahooProvider()
      : super(
          'yahoo',
          'imap.mail.yahoo.com',
          ClientConfig()
            ..emailProviders = [
              ConfigEmailProvider(
                displayName: 'Yahoo! Mail',
                displayShortName: 'Yahoo',
                incomingServers: [
                  ServerConfig(
                    type: ServerType.imap,
                    hostname: 'imap.mail.yahoo.com',
                    port: 993,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
                outgoingServers: [
                  ServerConfig(
                    type: ServerType.smtp,
                    hostname: 'smtp.mail.yahoo.com',
                    port: 465,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
              )
            ],
          appSpecificPasswordSetupUrl:
              'https://help.yahoo.com/kb/SLN15241.html',
          domains: [
            'yahoo.com',
            'yahoo.de',
            'yahoo.it',
            'yahoo.fr',
            'yahoo.es',
            'yahoo.se',
            'yahoo.co.uk',
            'yahoo.co.nz',
            'yahoo.com.au',
            'yahoo.com.ar',
            'yahoo.com.br',
            'yahoo.com.mx',
            'ymail.com',
            'rocketmail.com',
            'mail.am0.yahoodns.net',
            'am0.yahoodns.net',
            'yahoodns.net'
          ],
        );
}

class AolProvider extends EmailServiceProvider {
  AolProvider()
      : super(
          'aol',
          'imap.aol.com',
          ClientConfig()
            ..emailProviders = [
              ConfigEmailProvider(
                displayName: 'AOL Mail',
                displayShortName: 'AOL',
                incomingServers: [
                  ServerConfig(
                    type: ServerType.imap,
                    hostname: 'imap.aol.com',
                    port: 993,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
                outgoingServers: [
                  ServerConfig(
                    type: ServerType.smtp,
                    hostname: 'smtp.aol.com',
                    port: 465,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
              )
            ],
          appSpecificPasswordSetupUrl:
              'https://help.aol.com/articles/Create-and-manage-app-password',
          domains: [
            'aol.com',
            'aim.com',
            'netscape.net',
            'netscape.com',
            'compuserve.com',
            'cs.com',
            'wmconnect.com',
            'aol.de',
            'aol.it',
            'aol.fr',
            'aol.es',
            'aol.se',
            'aol.co.uk',
            'aol.co.nz',
            'aol.com.au',
            'aol.com.ar',
            'aol.com.br',
            'aol.com.mx',
            'mail.gm0.yahoodns.net'
          ],
        );
}

class AppleProvider extends EmailServiceProvider {
  AppleProvider()
      : super(
          'apple',
          'imap.mail.me.com',
          ClientConfig()
            ..emailProviders = [
              ConfigEmailProvider(
                displayName: 'Apple iCloud',
                displayShortName: 'Apple',
                incomingServers: [
                  ServerConfig(
                    type: ServerType.imap,
                    hostname: 'imap.mail.me.com',
                    port: 993,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
                outgoingServers: [
                  ServerConfig(
                    type: ServerType.smtp,
                    hostname: 'smtp.mail.me.com',
                    port: 587,
                    socketType: SocketType.starttls,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
              )
            ],
          appSpecificPasswordSetupUrl:
              'https://support.apple.com/en-us/HT204397',
          domains: ['mac.com', 'me.com', 'icloud.com'],
        );
}

class GmxProvider extends EmailServiceProvider {
  GmxProvider()
      : super(
          'gmx',
          'imap.gmx.net',
          ClientConfig()
            ..emailProviders = [
              ConfigEmailProvider(
                displayName: 'GMX Freemail',
                displayShortName: 'GMX',
                incomingServers: [
                  ServerConfig(
                    type: ServerType.imap,
                    hostname: 'imap.gmx.net',
                    port: 993,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
                outgoingServers: [
                  ServerConfig(
                    type: ServerType.smtp,
                    hostname: 'mail.gmx.net',
                    port: 465,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
              )
            ],
          manualImapAccessSetupUrl:
              'https://hilfe.gmx.net/pop-imap/einschalten.html',
          domains: [
            'gmx.net',
            'gmx.de',
            'gmx.at',
            'gmx.ch',
            'gmx.eu',
            'gmx.biz',
            'gmx.org',
            'gmx.info'
          ],
        );
}

class MailboxOrgProvider extends EmailServiceProvider {
  MailboxOrgProvider()
      : super(
          'mailbox_org',
          'imap.gmx.net',
          ClientConfig()
            ..emailProviders = [
              ConfigEmailProvider(
                displayName: 'mailbox.org',
                displayShortName: 'mailbox',
                incomingServers: [
                  ServerConfig(
                    type: ServerType.imap,
                    hostname: 'imap.mailbox.org',
                    port: 993,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
                outgoingServers: [
                  ServerConfig(
                    type: ServerType.smtp,
                    hostname: 'smtp.mailbox.org',
                    port: 465,
                    socketType: SocketType.ssl,
                    authentication: Authentication.passwordClearText,
                    usernameType: UsernameType.emailAddress,
                  )
                ],
              )
            ],
          domains: ['mailbox.org'],
        );
}
