import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';

const int sliceSize = 16 * 1024;

///把二进制消息分片和汇总
class MessageSlice {
  Map<int, List<int>> sliceBuffer = {};
  int sliceBufferId = 0;

  Map<int, List<int>> slice(List<int> message) {
    int total = message.length;
    int remainder = total % sliceSize;
    int sliceCount = total ~/ sliceSize;
    if (remainder > 0) {
      sliceCount++;
    }
    var random = Random.secure();
    int randomNum = random.nextInt(1 << 32);
    Map<int, List<int>> slices = {};
    for (int i = 0; i < sliceCount; ++i) {
      List<int> data = Uint8List(3);
      data[0] = randomNum;
      data[1] = sliceCount;
      data[2] = i;
      int start = i * sliceSize;
      int end = (i + 1) * sliceSize;
      if (end < total) {
        data = CryptoUtil.concat(data, message.sublist(start, end));
      } else {
        data = CryptoUtil.concat(data, message.sublist(start));
      }
      slices[i] = data;
    }

    return slices;
  }

  List<int>? merge(List<int> data) {
    int id = data[0];
    if (id != sliceBufferId) {
      sliceBufferId = id;
      sliceBuffer = {};
    }
    int sliceCount = data[1];
    int i = data[2];
    if (sliceCount == 1) {
      sliceBufferId = 0;
      sliceBuffer = {};
      return data.sublist(3);
    } else {
      List<int>? sliceData = sliceBuffer[i];
      if (sliceData == null) {
        sliceBuffer[i] = data;
      }
      int sliceBufferSize = sliceBuffer.length;
      if (sliceBufferSize == sliceCount) {
        List<int> slices = [];
        for (int j = 0; j < sliceBufferSize; ++j) {
          sliceData = sliceBuffer[j];
          if (sliceData != null) {
            slices = CryptoUtil.concat(slices, sliceData.sublist(3));
          }
        }
        sliceBufferId = 0;
        sliceBuffer = {};
        return slices;
      }
    }
    return null;
  }
}
