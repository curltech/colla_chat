import 'package:colla_chat/entity/base.dart';

/// 邮件地址
class MailAddress extends BaseEntity {
  String name;
  String email;
  String? username;
  String? password;
  String? domain;
  String? imapServerHost;
  int imapServerPort = 993;
  bool imapServerSecure = true;
  String? imapServerConfig;
  String? popServerHost;
  int popServerPort = 995;
  bool popServerSecure = true;
  String? popServerConfig;
  String? smtpServerHost;
  int smtpServerPort = 465;
  bool smtpServerSecure = true;
  String? smtpServerConfig;
  bool isDefault = false;

  MailAddress(
      {required this.name,
      required this.email,
      this.username,
      this.domain,
      this.imapServerHost,
      this.imapServerPort = 993,
      this.popServerHost,
      this.popServerPort = 995,
      this.smtpServerHost,
      this.smtpServerPort = 465,
      this.isDefault = false}) {
    var emails = email.split('@');
    username = emails[0];
    domain = emails[1];
  }

  MailAddress.fromJson(super.json)
      : name = json['name'],
        username = json['username'],
        password = json['password'],
        domain = json['domain'],
        email = json['email'],
        imapServerHost = json['imapServerHost'],
        imapServerPort = json['imapServerPort'],
        imapServerSecure =
            json['imapServerSecure'] == true || json['imapServerSecure'] == 1
                ? true
                : false,
        imapServerConfig = json['imapServerConfig'],
        popServerHost = json['popServerHost'],
        popServerPort = json['popServerPort'],
        popServerSecure =
            json['popServerSecure'] == true || json['popServerSecure'] == 1
                ? true
                : false,
        popServerConfig = json['popServerConfig'],
        smtpServerHost = json['smtpServerHost'],
        smtpServerPort = json['smtpServerPort'],
        smtpServerSecure =
            json['smtpServerSecure'] == true || json['smtpServerSecure'] == 1
                ? true
                : false,
        smtpServerConfig = json['smtpServerConfig'],
        isDefault =
            json['isDefault'] == true || json['isDefault'] == 1 ? true : false,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'name': name,
      'username': username,
      'password': password,
      'domain': domain,
      'email': email,
      'imapServerHost': imapServerHost,
      'imapServerPort': imapServerPort,
      'imapServerSecure': imapServerSecure,
      'imapServerConfig': imapServerConfig,
      'popServerHost': popServerHost,
      'popServerPort': popServerPort,
      'popServerSecure': popServerSecure,
      'popServerConfig': popServerConfig,
      'smtpServerHost': smtpServerHost,
      'smtpServerPort': smtpServerPort,
      'smtpServerSecure': smtpServerSecure,
      'smtpServerConfig': smtpServerConfig,
      'isDefault': isDefault,
    });
    return json;
  }
}
