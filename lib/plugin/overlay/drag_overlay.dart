import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 可拖拽的overlay浮动框
class DragOverlay {
  OverlayEntry? overlayEntry;
  final double top;
  final Widget child;

  DragOverlay({this.top = 20.0, required this.child});

  OverlayEntry _buildDraggableWidget() {
    OverlayEntry overlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return Positioned(
              top: top, right: 0, child: _buildDraggable(context));
        });

    return overlayEntry;
  }

  /// 创建定制（child不为空）可拖拽的浮动框
  Widget _buildDraggable(context) {
    return Draggable(
      feedback: child,
      onDragStarted: () {},
      onDragEnd: (DraggableDetails detail) {
        //放手时候创建一个DragTarget
        _createDragTarget(context, detail.offset);
      },
      //当拖拽的时候就展示空
      childWhenDragging: nil,
      ignoringFeedbackSemantics: false,
      child: child,
    );
  }

  void _createDragTarget(BuildContext context, Offset offset) {
    var size = MediaQuery.sizeOf(context);
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
    close();
    overlayEntry = OverlayEntry(builder: (context) {
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
            return _buildDraggable(context);
          },
        ),
      );
    });
    Overlay.of(context).insert(overlayEntry!);
  }

  close() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry!.dispose();
      overlayEntry = null;
    }
  }

  /// 增加并显示一个新的浮动框，用于外部调用
  show(BuildContext context) {
    close();
    overlayEntry = _buildDraggableWidget();
    Overlay.of(context).insert(overlayEntry!);
  }
}
