import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/type_util.dart';

import '../../crypto/util.dart';
import '../../entity/dht/myself.dart';
import '../../entity/dht/peerclient.dart';
import '../../entity/p2p/datablock.dart';
import '../../p2p/chain/action/queryvalue.dart';
import '../base.dart';
import '../dht/peerclient.dart';

class DataBlockService extends BaseService {
  DataBlockService({required super.tableName, required super.fields});

  static DataBlock create(
      blockId,
      parentBusinessNumber,
      businessNumber,
      blockType,
      String? createTimestamp,
      dynamic payload,
      List<PeerClient> peers) {
    var dataBlock = DataBlock();
    dataBlock.blockId = blockId;
    dataBlock.parentBusinessNumber = parentBusinessNumber;
    dataBlock.businessNumber = businessNumber;
    dataBlock.blockType = blockType;
    dataBlock.createTimestamp = createTimestamp;
    if (payload) {
      dataBlock.payload = payload.payload;
      dataBlock.metadata = payload.metadata;
      dataBlock.thumbnail = payload.thumbnail;
      dataBlock.name = payload.name;
      dataBlock.description = payload.description;
      dataBlock.expireDate = payload.expireDate;
      dataBlock.mimeType = payload.mimeType;
    }
    if (peers.isNotEmpty) {
      List<TransactionKey> transactionKeys = [];
      for (var peer in peers) {
        var transactionKey = TransactionKey();
        transactionKey.blockId = blockId;
        transactionKey.peerId = peer.peerId;
        transactionKey.publicKey = peer.publicKey;
        transactionKeys.add(transactionKey);
      }
      dataBlock.transactionKeys = transactionKeys;
    }

    return dataBlock;
  }

  /// 加密后，传输前分片，对每个交易单独进行分片，可以多线程同步传输
  ///
  /// @param dataBlock
  /// @return []
  static Future<List<DataBlock>> slice(DataBlock dataBlock) async {
    var sliceSize = dataBlock.sliceSize;
    List<DataBlock> dataBlocks = [];
    /**
     * 只有在没有分片的情况下才能分片
     */
    if (sliceSize == null) {
      // 对每一个块分片
      var sliceHashs = [];
      var slice0 = null;
      var transportPayload = dataBlock.transportPayload;
      var expireDate = dataBlock.expireDate;
      var mimeType = dataBlock.mimeType;
      DataBlock db;
      var slicePayload = null;
      if (transportPayload != null && transportPayload.length > sliceLimit) {
        sliceSize = transportPayload.length ~/ sliceLimit;
        sliceSize = sliceSize.ceil();
        for (var i = 0; i < sliceSize!; ++i) {
          // 第一个分片
          if (i == 0) {
            db = dataBlock;
            slice0 = db;
          } else {
            // 第n个分片
            db = DataBlock();
            //ObjectUtil.copy(dataBlock, db);
            db.transportKey = null;
            db.stateHash = null;
          }
          db.sliceNumber = i + 1;
          db.sliceSize = sliceSize;
          db.expireDate = expireDate;
          db.mimeType = mimeType;
          if (i == sliceSize! - 1) {
            slicePayload = transportPayload!
                .substring(i * sliceLimit, transportPayload.length);
          } else {
            slicePayload = transportPayload!
                .substring(i * sliceLimit, (i + 1) * sliceLimit);
          }
          db.transportPayload = slicePayload;
          // 每个块的负载计算hash
          await DataBlockService.sign(db);
          dataBlocks.add(db);
          sliceHashs.add(db.payloadHash);
        }
      } else {
        dataBlock.sliceNumber = 1;
        dataBlock.sliceSize = 1;
        // 每个块的负载计算hash
        await DataBlockService.sign(dataBlock);
        dataBlocks.add(dataBlock);
        sliceHashs.add(dataBlock.payloadHash);
      }
      //每个交易分片结束
      if (sliceHashs.length > 0) {
        // var stateHashs = await merkleTree.buildStringTree(sliceHashs);
        // if (slice0) {
        //   slice0.stateHash =
        //       CryptoUtil.encodeBase64(stateHashs[stateHashs.length - 1]);
        // }
      }
    }

    return dataBlocks;
  }

  static sign(DataBlock dataBlock) async {
    var privateKey = myself.privateKey;
    if (privateKey == null) {
      throw 'NullPrivateKey';
    }
    var signatureData;
    var transportPayload = dataBlock.transportPayload;
    if (transportPayload != null) {
      // 设置数据的hash
      var payloadHash = await cryptoGraphy.hash(transportPayload!.codeUnits);
      dataBlock.payloadHash = CryptoUtil.encodeBase64(payloadHash);
      signatureData = transportPayload;
    } else {
      dataBlock.expireDate = DateUtil.currentDate();
      signatureData = dataBlock.expireDate! + dataBlock!.peerId!;
    }
    // 设置签名
    var signature = await cryptoGraphy.sign(signatureData, privateKey);
    dataBlock.signature = String.fromCharCodes(signature);
  }

  static verify(DataBlock dataBlock) async {
    // 消息的数据部分，验证签名
    var peerId = dataBlock.peerId;
    var transportPayload = dataBlock.transportPayload;
    var signature = dataBlock.signature;
    if (peerId == myself.peerId) {
      var srcPublicKey = myself.publicKey;
      var pass = await cryptoGraphy.verify(
          transportPayload!.codeUnits, signature!.codeUnits,
          publicKey: srcPublicKey);
      if (!pass) {
        var i = 0;
        while (!pass && i < myself.expiredKeys.length) {
          pass = await cryptoGraphy.verify(
              transportPayload!.codeUnits, signature!.codeUnits,
              publicKey: await myself.expiredKeys[i].extractPublicKey());
          i++;
        }
        if (!pass) {
          logger.e('TransportPayloadVerifyFailure');
          //throw new Error("TransportPayloadVerifyFailure")
        }
      }
    } else {
      var srcPublicKey = await peerClientService.getCachedPublicKey(peerId!);
      if (srcPublicKey == null) {
        throw 'NullSrcPublicKey';
      }
      var pass = await cryptoGraphy.verify(
          transportPayload!.codeUnits, signature!.codeUnits,
          publicKey: srcPublicKey);
      if (!pass) {
        logger.e('TransportPayloadVerifyFailure');
        //throw new Error("TransportPayloadVerifyFailure")
      }
    }
  }

  /// 按照blockId分组
  /// @param dbs
  static dynamic group(List<DataBlock> dbs) {
    if (dbs.isNotEmpty) {
      Map dbMap = {};
      for (var db in dbs) {
        var blockId = db.blockId;
        List<DataBlock> blocks;
        if (!dbMap[blockId]) {
          blocks = [];
          dbMap[blockId] = blocks;
        } else {
          blocks = dbMap[blockId];
        }
        blocks.add(db);
      }
      return dbMap;
    }

    return null;
  }

  /// 假设输入数组的blockId相同
  /// @param {*} dataBlocks
  static Future<DataBlock?> merge(List<DataBlock> dataBlocks) async {
    if (dataBlocks.isNotEmpty) {
      var sliceSize = dataBlocks[0].sliceSize;
      if (dataBlocks.length != sliceSize) {
        throw 'ErrorSize';
      }
      dataBlocks.sort((a, b) {
        return a.sliceNumber! - b.sliceNumber!;
      });
      var transportPayload = null;
      List<Future> ps = [];
      for (var i = 0; i < dataBlocks.length; ++i) {
        var dataBlock = dataBlocks[i];
        var sliceNumber = dataBlock.sliceNumber;
        if (i + 1 != sliceNumber) {
          throw 'ErrorSliceNumber';
        }
        var future = DataBlockService.verify(dataBlock);
        ;
        ps.add(future);
      }
      var slicePayloads = await Future.wait(ps);
      if (slicePayloads.isNotEmpty) {
        for (var slicePayload in slicePayloads) {
          if (slicePayload) {
            if (transportPayload == null) {
              transportPayload = slicePayload;
            } else {
              transportPayload = transportPayload + slicePayload;
            }
          }
        }
      }
      dataBlocks[0].transportPayload = transportPayload;
      return dataBlocks[0];
    }

    return null;
  }

  /// 客户端加密处理基本的DataBlock数据，加密每个交易的负载
  ///
  /// 假设基本数据已经存在，但是没有经过加密处理，分片处理，hash处理和签名处理
  encrypt(DataBlock dataBlock) async {
    // 设置客户端的基本属性
    dataBlock.peerId = myself.peerId;
    // 设置数据的时间戳
    dataBlock.createTimestamp ??= DateUtil.currentDate();
    // 如果有目标接受对象，需要加密处理，生成对称密钥
    var secretKey = null;
    var transactionKeys = dataBlock.transactionKeys;
    // 消息的数据部分转换成字符串，签名，加密，压缩，base64
    var privateKey = myself.privateKey;
    if (privateKey == null) {
      throw 'NullPrivateKey';
    }
    if (transactionKeys!.isNotEmpty) {
      secretKey = await cryptoGraphy.getRandomAsciiString();
      // 处理目标的加密密钥
      for (var transactionKey in transactionKeys) {
        // 对对称密钥进行公钥加密
        var targetPublicKey = null;
        if (transactionKey.peerId == myself.peerId) {
          targetPublicKey = myself.publicKey;
        } else {
          targetPublicKey = await peerClientService
              .getCachedPublicKey(transactionKey.peerId!);
        }
        if (!targetPublicKey) {
          logger.w('TargetPublicKey is null, will not be encrypted!');
          continue;
        }
        var secretKeyData = await cryptoGraphy.eccEncrypt(secretKey,
            remotePublicKey: targetPublicKey);
        transactionKey.payloadKey = String.fromCharCodes(secretKeyData);
        if (transactionKey.peerId == dataBlock.peerId) {
          dataBlock.payloadKey = transactionKey.payloadKey;
        }
      }
      // 设置目标签名
      var keyData = JsonUtil.toJsonString(dataBlock.transactionKeys);
      var keySignData = await cryptoGraphy.sign(keyData.codeUnits, privateKey);
      dataBlock.transactionKeySignature = String.fromCharCodes(keySignData);
      dataBlock.transportKey = CryptoUtil.encodeBase64(keyData.codeUnits);
      dataBlock.transactionKeys = null; // NOTE:上线前注释掉方便调试
    }
    // 对业务数据进行处理
    var transportPayload = dataBlock.transportPayload;
    if (transportPayload == null) {
      var payload = dataBlock.payload;
      if (payload) {
        transportPayload = JsonUtil.toJsonString(payload);
      }
    }
    if (transportPayload != null) {
      List<int>? data = CryptoUtil.stringToUtf8(transportPayload);
      // 压缩原始数据
      data = CryptoUtil.compress(data);
      // 对数据进行对称加密
      if (secretKey) {
        data = await cryptoGraphy.aesEncrypt(data, secretKey);
      }
      // 最终的数据放入
      dataBlock.transportPayload = CryptoUtil.encodeBase64(data);
    }
    dataBlock.payload = null; // NOTE:上线前注释掉方便调试
  }

  /// 接受者解密（如果加密的化），在分片合并，校验DataBlock数据后执行解密
  decrypt(DataBlock dataBlock, bool verify) async {
    var transactionKeys = dataBlock.transactionKeys;

    if (transactionKeys == null && dataBlock.transportKey != null) {
      var transportKey = CryptoUtil.decodeBase64(dataBlock.transportKey!);
      if (transportKey != null) {
        // Keys，验证签名
        var keySignature = dataBlock.transactionKeySignature;
        if (keySignature != null && verify == true) {
          if (dataBlock.peerId == myself.peerId) {
            var srcPublicKey = myself.publicKey;
            var pass = await cryptoGraphy.verify(
                transportKey, keySignature.codeUnits,
                publicKey: srcPublicKey);
            if (!pass) {
              var i = 0;
              while (!pass && i < myself.expiredKeys.length) {
                pass = await cryptoGraphy.verify(
                    transportKey, keySignature.codeUnits,
                    publicKey: await myself.expiredKeys[i].extractPublicKey());
                i++;
              }
              if (!pass) {
                logger.e('TransactionKeyVerifyFailure');
                //throw new Error("TransactionKeyVerifyFailure")
              }
            }
          } else {
            var srcPublicKey =
                await peerClientService.getCachedPublicKey(dataBlock.peerId!);
            if (srcPublicKey == null) {
              throw 'NullSrcPublicKey';
            }
            var pass = await cryptoGraphy.verify(
                transportKey, keySignature.codeUnits,
                publicKey: srcPublicKey);
            if (!pass) {
              logger.e('TransactionKeyVerifyFailure');
              //throw new Error("TransactionKeyVerifyFailure")
            }
          }
        }
        transactionKeys = JsonUtil.toJson(transportKey);
        dataBlock.transactionKeys = transactionKeys;
      }
    }
    // 如果数据被加密，处理目标的加密密钥
    var secretKey = null;

    if (transactionKeys != null && transactionKeys.isNotEmpty) {
      for (var transactionKey in transactionKeys) {
        // 找到正确的公钥
        if (transactionKey.peerId == myself.peerId) {
          var payloadKey = transactionKey.payloadKey;
          if (payloadKey != null) {
            var privateKey = myself.privateKey;
            if (privateKey == null) {
              throw 'NullPrivateKey';
            }
            try {
              secretKey = await cryptoGraphy.eccDecrypt(payloadKey.codeUnits,
                  localKeyPair: privateKey);
            } catch (e) {
              logger.e(e);
            }
            var i = 0;
            while (!secretKey && i < myself.expiredKeys.length) {
              try {
                secretKey = await cryptoGraphy.eccDecrypt(payloadKey.codeUnits,
                    localKeyPair: myself.expiredKeys[i]);
              } catch (e) {
                logger.e(e);
              } finally {
                i++;
              }
            }
            if (!secretKey) {
              throw 'EccDecryptFailed';
            }
          }
        }
      }
    }
    // 处理数据
    var transportPayload = dataBlock.transportPayload;

    if (transportPayload != null) {
      List<int> data = CryptoUtil.decodeBase64(transportPayload);
      // 数据解密
      if (secretKey) {
        try {
          data = await cryptoGraphy.aesDecrypt(data, secretKey);
        } catch (err) {
          logger.e('data cannot aesDecrypt');
        }
      }
      var payload = null;
      if (data != null) {
        // 解压缩
        data = CryptoUtil.uncompress(data);
        // 还原数据
        var str = CryptoUtil.uint8ListToStr(data);
        payload = JsonUtil.toJson(str);
      }
      dataBlock.payload = payload;
      dataBlock.transportPayload = null;
    }
  }

  blockMerge(Map dbMap) async {
    var blocks = [];
    if (dbMap != null) {
      // 每个不同的块号循环
      for (var key in dbMap.keys) {
        var dataBlocks = dbMap[key];
        if (dataBlocks &&
            TypeUtil.isArray(dataBlocks) &&
            dataBlocks.length > 0) {
          var db = await DataBlockService.merge(dataBlocks);
          await decrypt(db!, true);
          blocks.add(db);
        }
      }
    }
    return blocks;
  }

  blockMapMerge(Map targetMap, Map dbMap) async {
    if (dbMap != null) {
      var blocks = [];
      // 每个不同的块号循环
      for (var key in dbMap.keys) {
        var ts = targetMap[key];
        if (!ts) {
          ts = [];
          targetMap[key] = ts;
        }
        var dataBlocks = dbMap[key];
        if (dataBlocks &&
            TypeUtil.isArray(dataBlocks) &&
            dataBlocks.length > 0) {
          for (var dataBlock in dataBlocks) {
            ts.push(dataBlock);
          }
        }
      }
    }
  }

  /// 最基本的根据条件查询block的操作，返回满足条件的block的Map
  ///
  /// @param {*} connectPeerId
  /// @param {*} conditionBean
  /// @param {*} options
  _find(String connectPeerId,
      {required Map conditionBean, required Map options}) async {
    Map blockMap = {};
    conditionBean['receiverPeerId'] = myself.peerId;
    if (options != null) {
      if (options['createPeer'] == true) {
        conditionBean['createPeerId'] = myself.peerId;
      }
      if (options['receiverPeer'] == true) {
        conditionBean['receiverPeer'] = true;
      }
    }
    List? blocks = await queryValueAction.queryValue(conditionBean);
    if (blocks != null && TypeUtil.isArray(blocks)) {
      blockMap = DataBlockService.group(blocks as List<DataBlock>);
    }

    return blockMap;
  }

  loadUrl(url, uriVariables) async {
    var html;

    return html;
  }

  /// 获取块中的负载
  ///
  /// @param {*} dataBlocks
  getPayload(List<DataBlock> dataBlocks) {
    if (dataBlocks.isNotEmpty) {
      var data = [];
      // 循环不同的块号
      for (var dataBlock in dataBlocks) {
        if (dataBlock.blockType == BlockType.p2pChat.name) {
          data.add(dataBlock);
        } else {
          var d = dataBlock.payload;
          if (d) {
            d.blockId = dataBlock.blockId;
            d.sliceNumber = dataBlock.sliceNumber;
            d.sliceSize = dataBlock.sliceSize;
            data.add(d);
          }
        }
      }
      return data;
    }

    return null;
  }

  /// 根据块号从云端获取全部分片数据
  ///
  /// 返回block的Map
  ///
  /// @param {*} connectPeerId
  /// @param {*} blockId
  findTx(connectPeerId, blockId) async {
    /**
     * 首先获取所有交易的第1个分片
     */
    var blockMap = await _find(connectPeerId,
        options: {'blockId': blockId, 'sliceNumber': 1}, conditionBean: {});
    if (blockMap) {
      var block = blockMap[blockId];
      if (block) {
        var sliceSize = block[0].sliceSize;
        logger.i('${'blockId:' + blockId};sliceSize:' + sliceSize);
        if (sliceSize && sliceSize > 1) {
          List<Future> ps = [];
          /**
           * 获取第一个分片以后的分片
           */
          for (var i = 2; i <= sliceSize; ++i) {
            var future = _find(connectPeerId,
                options: {'blockId': blockId, 'sliceNumber': i},
                conditionBean: {});
            ps.add(future);
          }
          var blocks = await Future.wait(ps);
          /**
           * 合并所有的分片
           */
          if (blocks != null && blocks.length > 0) {
            for (var bs in blocks) {
              await blockMapMerge(blockMap, bs);
            }
          }
        }
      }
    }

    return blockMap;
  }

  /// 根据块号从云端获取全部分片数据的合并负载
  ///
  /// 返回block的payload
  ///
  /// @param {*} connectPeerId
  /// @param {*} blockId
  findTxPayload(String connectPeerId, String blockId) async {
    var blockMap = await findTx(connectPeerId, blockId);
    var dataBlocks = await blockMerge(blockMap);
    var data = getPayload(dataBlocks);

    return data;
  }
}
