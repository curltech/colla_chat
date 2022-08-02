import 'package:flutter/material.dart';

import '../../../../entity/dht/peerclient.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_listshow.dart';

final List<String> peerClientFields = ['id', 'name', 'peerId'];

//邮件内容组件
class PeerClientShowWidget extends StatefulWidget with TileDataMixin {
  final DataPageController<PeerClient> controller;

  const PeerClientShowWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerClientShowWidgetState();

  @override
  String get routeName => 'peer_client_show';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerClientShow';
}

class _PeerClientShowWidgetState extends State<PeerClientShowWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildDataListShow(BuildContext context) {
    Map<String, dynamic> values = {};
    PeerClient? currentPeerClient = widget.controller.current;
    if (currentPeerClient != null) {
      var peerClientMap = currentPeerClient.toJson();
      for (var peerClientField in peerClientFields) {
        var label = peerClientField;
        var value = peerClientMap[peerClientField];
        value = value ?? '';
        values[label] = value;
      }
    }
    Widget dataListShow = DataListShow(
      values: values,
    );
    return dataListShow;
  }

  @override
  Widget build(BuildContext context) {
    var dataListShow = _buildDataListShow(context);
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: dataListShow);
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
