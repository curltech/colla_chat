import 'package:flutter/cupertino.dart';

import '../../plugin/logger.dart';

class DragOverlay {
  OverlayEntry? overlayEntry;
  Widget child;

  DragOverlay(this.child);

  void dispose() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  void show({required BuildContext context, required Widget child}) {
    overlayEntry = OverlayEntry(
        maintainState: true,
        builder: (context) {
          return Positioned(
            top: 0,
            right: 0,
            child: _buildDraggable(context),
          );
        });
    Overlay.of(context)!.insert(overlayEntry!);
  }

  Draggable _buildDraggable(context) {
    return Draggable(
      feedback: child,
      onDragStarted: () {},
      onDragEnd: (DraggableDetails detail) {
        logger.i("onDragEnd:${detail.offset}");
        //放手时候创建一个DragTarget
        createDragTarget(offset: detail.offset, context: context);
      },
      //当拖拽的时候就展示空
      childWhenDragging: Container(),
      ignoringFeedbackSemantics: false,
      child: child,
    );
  }

  void createDragTarget(
      {required Offset offset, required BuildContext context}) {
    if (overlayEntry != null) {
      overlayEntry!.remove();
    }
    overlayEntry = OverlayEntry(builder: (context) {
      bool isLeft = true;
      if (offset.dx + 100 > MediaQuery.of(context).size.width / 2) {
        isLeft = false;
      }
      double maxY = MediaQuery.of(context).size.height - 100;

      return Positioned(
        top: offset.dy < 50
            ? 50
            : offset.dy > maxY
                ? maxY
                : offset.dy,
        left: isLeft ? 0 : null,
        right: isLeft ? null : 0,
        child: DragTarget(
          onWillAccept: (data) {
            logger.i('onWillAccept:$data');

            ///返回true 会将data数据添加到candidateData列表中，false时会将data添加到rejectData
            return true;
          },
          onAccept: (data) {
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
    Overlay.of(context)!.insert(overlayEntry!);
  }
}
