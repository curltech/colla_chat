class SecurityContext {
  /// 消息负载序列化后的寄送格式，再经过客户端自己的加密方式比如openpgp（更安全）加密，签名，压缩，base64处理后的字符串
  String transportPayload = '';

  /// 负载json的源peer的签名
  String? payloadSignature;
  String? previousPublicKeyPayloadSignature;
  bool needCompress = true;
  bool needEncrypt = true;
  bool needSign = false;

  /// 经过目标peer的公钥加密过的对称密钥，这个对称密钥是随机生成，每次不同，用于加密payload
  /// 如果为null，表示直接ecc加解密，无对称密钥，如果不为空，secretKey为空，表示产生一个新的对称密钥返回
  String? payloadKey;
  List<int>? secretKey;
  String? targetPeerId;
  String? srcPeerId;
  String? payloadHash;

  SecurityContext();

  SecurityContext.fromJson(Map json)
      : transportPayload = json['transportPayload'] ?? '',
        payloadSignature = json['payloadSignature'],
        previousPublicKeyPayloadSignature =
            json['previousPublicKeyPayloadSignature'],
        needCompress = json['needCompress'] == true || json['needCompress'] == 1
            ? true
            : false,
        needEncrypt = json['needEncrypt'] == true || json['needEncrypt'] == 1
            ? true
            : false,
        needSign =
            json['needSign'] == true || json['needSign'] == 1 ? true : false,
        payloadKey = json['payloadKey'],
        targetPeerId = json['targetPeerId'],
        srcPeerId = json['srcPeerId'],
        payloadHash = json['payloadHash'];

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    json.addAll({
      'transportPayload': transportPayload,
      'payloadSignature': payloadSignature,
      'previousPublicKeyPayloadSignature': previousPublicKeyPayloadSignature,
      'needCompress': needCompress,
      'needEncrypt': needEncrypt,
      'needSign': needSign,
      'payloadKey': payloadKey,
      'targetPeerId': targetPeerId,
      'srcPeerId': srcPeerId,
      'payloadHash': payloadHash,
    });
    return json;
  }
}
