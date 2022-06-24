import '../base.dart';

/// 邮件地址
class MailAddress extends BaseEntity {
  String? ownerPeerId;
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

  MailAddress.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        name = json['name'],
        username = json['username'],
        password = json['password'],
        domain = json['domain'],
        email = json['email'],
        imapServerHost = json['imapServerHost'],
        imapServerPort = json['imapServerPort'],
        imapServerSecure = json['imapServerSecure'],
        imapServerConfig = json['imapServerConfig'],
        popServerHost = json['popServerHost'],
        popServerPort = json['popServerPort'],
        popServerSecure = json['popServerSecure'],
        popServerConfig = json['popServerConfig'],
        smtpServerHost = json['smtpServerHost'],
        smtpServerPort = json['smtpServerPort'],
        smtpServerSecure = json['smtpServerSecure'],
        smtpServerConfig = json['smtpServerConfig'],
        isDefault = json['isDefault'],
        super.fromJson(json);

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
