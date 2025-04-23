import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that provides a callback that is triggered when its size changes even when it is offstage.
class SizeObserverWidget extends SingleChildRenderObjectWidget {
  const SizeObserverWidget(
      {super.key,
      required this.onSizeChanged,
      this.offstage = false,
      super.child});

  /// Callback that gets triggered when the size of the widget changes.
  final void Function(Size size) onSizeChanged;

  /// Whether the child is hidden from the rest of the tree.
  final bool offstage;

  @override
  SizeObserverRenderBox createRenderObject(BuildContext context) {
    return SizeObserverRenderBox(
        onSizeChanged: onSizeChanged, offstage: offstage);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant SizeObserverRenderBox renderObject) {
    renderObject.onSizeChanged = onSizeChanged;
    renderObject.offstage = offstage;
  }
}

class SizeObserverRenderBox extends RenderProxyBox {
  SizeObserverRenderBox({
    RenderBox? child,
    required this.onSizeChanged,
    bool offstage = true,
  })  : _offstage = offstage,
        super(child);

  void Function(Size) onSizeChanged;
  Size? _actualSize;
  bool _offstage;

  bool get offstage => _offstage;

  set offstage(bool value) {
    if (value == _offstage) {
      return;
    }
    _offstage = value;
    markNeedsLayoutForSizedByParentChange();
  }

  @override
  void performLayout() {
    super.performLayout();
    if (_actualSize != size) {
      _actualSize = size;
      onSizeChanged.call(size);
    }
    if (_offstage) {
      size = constraints.smallest;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (_offstage) {
      return constraints.smallest;
    }
    return super.computeDryLayout(constraints);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return !_offstage && super.hitTest(result, position: position);
  }

  @override
  bool paintsChild(RenderBox child) {
    return !_offstage;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_offstage) {
      return;
    }
    super.paint(context, offset);
  }
}
