enum CryptoOption { none, compress, linkman, group, web, openpgp, signal }

class SecurityContext {
  int cryptoOptionIndex = CryptoOption.linkman.index;
  String? targetPeerId;
  String? targetClientId;
  String? srcPeerId;

  bool needCompress = true;
  bool needEncrypt = true;
  bool needSign = false;

  /// 不跨网络传输，是transportPayload检验过后还原的对象，传输时通过转换成transportPayload传输
  /// 二进制的消息，将被加密或者解密
  dynamic payload;

  /// 如果为null，表示直接ecc加解密，无对称密钥，如果不为空，secretKey为空，表示产生一个新的对称密钥返回
  /// 经过目标peer的公钥加密过的对称密钥，这个对称密钥是随机生成，每次不同，用于加密payload
  String? payloadKey;

  ///未加密的对称密码加密的密码，如果不为空则直接使用，用于群加密
  ///如果为空，则表示第一次加密，需要随机数生成，可以用于群加密的后续peer
  List<int>? secretKey;

  /// 负载json的源peer的签名
  String? payloadSignature;
  String? previousPublicKeyPayloadSignature;

  String? payloadHash;

  SecurityContext({this.targetPeerId, this.targetClientId, this.srcPeerId});

  SecurityContext.fromJson(Map json)
      : cryptoOptionIndex =
            json['cryptoOptionIndex'] ?? CryptoOption.linkman.index,
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
        targetClientId = json['targetClientId'],
        srcPeerId = json['srcPeerId'],
        payloadHash = json['payloadHash'];

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    json.addAll({
      'cryptoOptionIndex': cryptoOptionIndex,
      'payloadSignature': payloadSignature,
      'previousPublicKeyPayloadSignature': previousPublicKeyPayloadSignature,
      'needCompress': needCompress,
      'needEncrypt': needEncrypt,
      'needSign': needSign,
      'payloadKey': payloadKey,
      'targetPeerId': targetPeerId,
      'targetClientId': targetClientId,
      'srcPeerId': srcPeerId,
      'payloadHash': payloadHash,
    });
    return json;
  }
}
