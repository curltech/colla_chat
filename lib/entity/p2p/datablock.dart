import '../base.dart';

const sliceLimit = 1024 * 1024 * 1024;

class TransactionKey extends BaseEntity {
  /// 经过目标peer的公钥加密过的对称密钥，这个对称密钥是随机生成，每次不同，用于加密payload
  String? blockId;
  String? peerId;

  ///key是blockId:peerId，用于key检索和存储
  String? key;
  String? payloadKey;
  String? publicKey;
  String? address;
  String? peerType;
}

class DataBlock extends StatusEntity {
  String? blockId;
  String? parentBusinessNumber;
  String? businessNumber;
  String? blockType;

  /// 双方的公钥不能被加密传输，因为需要根据公钥决定配对的是哪一个版本的私钥
  /// 对方的公钥有可能不存在，这时候数据没有加密，对称密钥也不存在
  /// 自己的公钥始终存在，因此签名始终可以验证
  String? peerId;
  String? publicKey;
  String? address;
  String? securityContext;

  /// 经过源peer的公钥加密过的对称密钥，这个对称密钥是随机生成，每次不同，用于加密payload
  ///
  /// 如果本字段不为空，表示负载被加密了，至少是只有源peer能够解密
  ///
  /// 这样处理的好处是判断是否加密只需datablock，而且如果只是源peer的收藏，则transactionkey为空
  dynamic payload;
  String? payloadKey;
  String? transportPayload;

  /// transactionKeys的寄送格式，每个交易的第一个分片有数据，保证每个交易可以单独被查看
  String? transportKey;

  /// 本数据块的负载被拆成分片的总数，在没有分片前是1，分片后>=1，同一交易负载的交易号相同
  int? sliceSize;

  /// 数据块的本条分片是交易负载的第几个分片，在没有分片前是1，分片后>=1，但是<=sliceSize
  int? sliceNumber;

  /// 负载源peer的签名
  String? signature;

  /// 块负载的hash，是负载的decode64 hash，然后encode64
  String? payloadHash;
  double? transactionAmount;

  // 由区块提议者填充的时间戳
  String? createTimestamp;
  String? expireDate;

  /// 当在一个事务中的一批交易开始执行的时候，首先保存交易，状态是Draft，
  ///
  /// 交易在共识后真正执行完毕状态变为effective，生成blockId
  ///
  /// 交易被取消，状态变成Ineffective
  // 请求的排好序的序号
  int? primarySequenceId;

  /// 分片hash汇总到交易，交易汇总到块hash
  String? stateHash;
  String? previousBlockId;

  // 前一个区块的全局hash，也就是0:0的stateHash
  String? previousBlockHash;

  // 共识可能会引入的一些可选的元数据
  String? metadata;
  String? name;
  String? description;
  String? thumbnail;
  String? mimeType;
  List<TransactionKey>? transactionKeys;

  /// 是负载的decode64 signature，然后encode64
  String? transactionKeySignature;

  /// chainApp
  String? chainAppPeerId;
  String? chainAppPublicKey;
  String? chainAppAddress;

  /// primary peer
  String? primaryPeerId;
  String? primaryPublicKey;
  String? primaryAddress;

  String? peerIds;
}

enum BlockType {
  // 聊天
  p2pChat,
  // 聊天附件
  chatAttach,
  // 收藏
  collection,
  // 群文件
  groupFile,
  channel,
  // 频道文章
  channelArticle,
}
