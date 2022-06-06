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

  MailAddress();

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
      'email': email,
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
