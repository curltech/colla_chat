import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/cupertino.dart';

class DragOverlay {
  OverlayEntry? overlayEntry;
  Widget child;
  double top = 20.0;

  DragOverlay({required this.child});

  void show({required BuildContext context}) {
    overlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return Positioned(
            top: top,
            right: 0,
            child: _buildDraggable(context),
          );
        });
    Overlay.of(context).insert(overlayEntry!);
  }

  Draggable _buildDraggable(context) {
    return Draggable(
      feedback: child,
      onDragStarted: () {},
      onDragEnd: (DraggableDetails detail) {
        //放手时候创建一个DragTarget
        createDragTarget(
          context: context,
          offset: detail.offset,
        );
      },
      //当拖拽的时候就展示空
      childWhenDragging: Container(),
      ignoringFeedbackSemantics: false,
      child: child,
    );
  }

  void createDragTarget(
      {required BuildContext context, required Offset offset}) {
    if (overlayEntry != null) {
      overlayEntry!.remove();
    }
    var size = MediaQuery.of(context).size;
    overlayEntry = OverlayEntry(builder: (context) {
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

  void dispose() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }
}
