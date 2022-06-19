import '../base.dart';

/// 邮件地址
class MailAddress extends BaseEntity {
  String? ownerPeerId;
  String? name;
  String? username;
  String? password;
  String? domain;
  String? email;
  String? imapServerHost;
  int imapServerPort = 143;
  bool imapServerSecure = true;
  String? popServerHost;
  int popServerPort = 110;
  bool popServerSecure = true;
  String? smtpServerHost;
  int smtpServerPort = 25;
  bool smtpServerSecure = true;
  bool isDefault = false;

  MailAddress(
      {this.name,
      this.username,
      this.domain,
      this.email,
      this.imapServerHost,
      this.imapServerPort = 143,
      this.popServerHost,
      this.popServerPort = 110,
      this.smtpServerHost,
      this.smtpServerPort = 25,
      this.isDefault = false}) {
    email = '$username@$domain';
  }

  MailAddress.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        name = json['name'],
        username = json['username'],
        password = json['password'],
        domain = json['domain'],
        email = json['mail'],
        imapServerHost = json['imapServerHost'],
        imapServerPort = json['imapServerPort'],
        imapServerSecure = json['imapServerSecure'],
        popServerHost = json['popServerHost'],
        popServerPort = json['popServerPort'],
        popServerSecure = json['popServerSecure'],
        smtpServerHost = json['smtpServerHost'],
        smtpServerPort = json['smtpServerPort'],
        smtpServerSecure = json['smtpServerSecure'],
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
      'mail': email,
      'imapServerHost': imapServerHost,
      'imapServerPort': imapServerPort,
      'imapServerSecure': imapServerSecure,
      'popServerHost': popServerHost,
      'popServerPort': popServerPort,
      'popServerSecure': popServerSecure,
      'smtpServerHost': smtpServerHost,
      'smtpServerPort': smtpServerPort,
      'smtpServerSecure': smtpServerSecure,
      'isDefault': isDefault,
    });
    return json;
  }
}
