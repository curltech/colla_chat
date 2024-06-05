import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/cupertino.dart';

/// 平台定制的overlay浮动框
class PlatformOverlay {
  final Map<String, OverlayEntry> _overlayEntries = {};
  Widget child;
  final double top;
  final bool isDraggable;

  PlatformOverlay(
      {this.top = 20.0, this.isDraggable = false, required this.child});

  /// 增加并显示一个新的浮动框
  String show(BuildContext context) {
    Key uniqueKey = UniqueKey();
    String id = uniqueKey.toString();
    OverlayEntry overlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return isDraggable ? _buildDraggable(context, id) : child;
        });
    _overlayEntries[id] = overlayEntry;
    Overlay.of(context).insert(overlayEntry);

    return id;
  }

  Widget _buildDraggable(context, String id) {
    return Positioned(
        top: top,
        right: 0,
        child: Draggable(
          feedback: child,
          onDragStarted: () {},
          onDragEnd: (DraggableDetails detail) {
            //放手时候创建一个DragTarget
            _createDragTarget(context, detail.offset, id);
          },
          //当拖拽的时候就展示空
          childWhenDragging: Container(),
          ignoringFeedbackSemantics: false,
          child: child,
        ));
  }

  void _createDragTarget(BuildContext context, Offset offset, String id) {
    var size = MediaQuery.of(context).size;
    //最大的高度是离底部100px
    double maxY = size.height - 80;
    //如果目标高度小于top，则取top，如果大于最大高度，则取最大高度，否则就是拖拽的目标高度
    double? left = offset.dx;
    double? right;
    if (left < 0) {
      left = 0;
    }
    if (left > size.width - 100) {
      left = size.width - 100;
    }
    var top = offset.dy;
    if (offset.dy < this.top) {
      top = this.top;
    } else {
      if (offset.dy > maxY) {
        top = maxY;
      } else {
        top = offset.dy;
        if (offset.dx + 100 > size.width / 2) {
          left = null;
          right = 0;
        } else {
          left = 0;
        }
      }
    }

    dispose(id);
    OverlayEntry overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        top: top,
        left: left,
        right: right,
        child: DragTarget(
          onWillAcceptWithDetails: (data) {
            logger.i('onWillAccept:$data');

            ///返回true 会将data数据添加到candidateData列表中，false时会将data添加到rejectData
            return true;
          },
          onAcceptWithDetails: (data) {
            logger.i('onAccept : $data');
          },
          onLeave: (data) {
            logger.i("onLeave");
          },
          builder: (BuildContext context, List incoming, List rejected) {
            return _buildDraggable(context, id);
          },
        ),
      );
    });
    _overlayEntries[id] = overlayEntry;
    Overlay.of(context).insert(overlayEntry);
  }

  void dispose(String id) {
    OverlayEntry? overlayEntry = _overlayEntries[id];
    if (overlayEntry != null) {
      _overlayEntries.remove(id);
      overlayEntry.remove();
      overlayEntry.dispose();
    }
  }

  void disposeAll() {
    for (String id in _overlayEntries.keys.toList()) {
      dispose(id);
    }
  }
}
