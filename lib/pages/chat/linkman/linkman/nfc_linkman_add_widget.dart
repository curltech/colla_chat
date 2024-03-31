import 'dart:async';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/nfc_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcLinkmanAddWidget extends StatefulWidget with TileDataMixin {
  const NfcLinkmanAddWidget({super.key});

  @override
  IconData get iconData => Icons.nfc;

  @override
  String get routeName => 'nfc_linkman_add';

  @override
  String get title => 'Nfc add linkman';

  @override
  bool get withLeading => true;

  @override
  State<NfcLinkmanAddWidget> createState() => _NfcLinkmanAddWidgetState();
}

class _NfcLinkmanAddWidgetState extends State<NfcLinkmanAddWidget> {
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String? _result;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    NFCAvailability availability;
    try {
      availability = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      availability = NFCAvailability.not_supported;
    }
    if (mounted) {
      setState(() {
        _availability = availability;
      });
    }
  }

  Future<String?> read() async {
    String? result;
    try {
      NFCTag tag = await NfcUtil.poll();
      if (tag.standard == "ISO 14443-4 (Type B)") {
        String? result1 = await NfcUtil.transceive("00B0950000");
        String result2 =
            await NfcUtil.transceive("00A4040009A00000000386980701");
        result = '1: $result1\n2: $result2\n';
      } else if (tag.type == NFCTagType.iso18092) {
        String result1 = await NfcUtil.transceive("060080080100");
        result = '1: $result1\n';
      } else if (tag.ndefAvailable ?? false) {
        var ndefRecords = await NfcUtil.read();
        var ndefString = '';
        for (int i = 0; i < ndefRecords.length; i++) {
          ndefString += '${i + 1}: ${ndefRecords[i]}\n';
        }
        result = ndefString;
      } else if (tag.type == NFCTagType.webusb) {
        result = await NfcUtil.transceive("00A4040006D27600012401");
      }
    } catch (e) {
      result = 'error: $e';
    }

    await NfcUtil.finish();

    return result;
  }

  write(String data) async {
    try {
      _tag = await NfcUtil.poll();
      if (_tag == null) {
        return;
      }
      if (_tag!.type == NFCTagType.mifare_ultralight ||
          _tag!.type == NFCTagType.mifare_classic ||
          _tag!.type == NFCTagType.iso15693) {
        await NfcUtil.write(data);
      } else {
        _result = 'error: NDEF not supported: ${_tag!.type}';
      }
    } catch (e, stacktrace) {
      _result = 'error: $e';
    } finally {
      await NfcUtil.finish();
    }
  }

  Widget _buildReadWidget() {
    return Column(
      children: [
        Text(
            'Running on: ${platformParams.operatingSystem}\nNFC: $_availability'),
        ElevatedButton(
          child: Text('Start polling'),
          onPressed: () async {
            _result = await read();
            setState(() {});
          },
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _tag != null
                ? Text(
                    'ID: ${_tag!.id}\nStandard: ${_tag!.standard}\nType: ${_tag!.type}\nATQA: ${_tag!.atqa}\nSAK: ${_tag!.sak}\nHistorical Bytes: ${_tag!.historicalBytes}\nProtocol Info: ${_tag!.protocolInfo}\nApplication Data: ${_tag!.applicationData}\nHigher Layer Response: ${_tag!.hiLayerResponse}\nManufacturer: ${_tag!.manufacturer}\nSystem Code: ${_tag!.systemCode}\nDSF ID: ${_tag!.dsfId}\nNDEF Available: ${_tag!.ndefAvailable}\nNDEF Type: ${_tag!.ndefType}\nNDEF Writable: ${_tag!.ndefWritable}\nNDEF Can Make Read Only: ${_tag!.ndefCanMakeReadOnly}\nNDEF Capacity: ${_tag!.ndefCapacity}\nMifare Info:${_tag!.mifareInfo} Transceive Result:\n$_result\n\n')
                : const Text('No tag polled yet.'))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: Column(children: [
          _buildReadWidget(),
          ElevatedButton(
            child: Text('Start writting'),
            onPressed: () async {
              await write('write data');
              setState(() {});
            },
          ),
        ]));
  }
}
