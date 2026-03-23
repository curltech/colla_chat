import 'package:flutter/material.dart';

abstract class Explorable {
  String name;
  String? comment;

  Explorable(this.name, {this.comment});

  @override
  String toString() => name;

  Explorable.fromJson(Map json)
      : name = json['name'],
        comment = json['comment'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'comment': comment,
    };
  }
}

class ExplorableNode {
  final Explorable value;

  Widget? get icon {
    return null;
  }

  ExplorableNode? parent;
  int originalIndex = 0;

  final ValueNotifier<List<ExplorableNode>> children =
      ValueNotifier<List<ExplorableNode>>([]);
  final ValueNotifier<bool> hidden = ValueNotifier<bool>(false);
  final ValueNotifier<bool> canBeExpanded = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSelected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPartiallySelected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCurrent = ValueNotifier<bool>(false);

  ExplorableNode(
    this.value, {
    this.parent,
    this.originalIndex = 0,
  }) {
    for (var child in children.value) {
      child.parent = this;
    }
  }
}

class TreeViewController {
  /// The root nodes of the tree.
  final List<ExplorableNode> roots;

  /// Callback function called when the selection state changes.
  final Function(List<Explorable?>)? onSelectionChanged;

  /// 是否显示"Select All"选择框按钮.
  final bool showSelectAll;

  /// 选择所有和去选择所有的扩展和收缩按钮
  final bool showExpandCollapseButton;

  /// The number of levels to initially expand. If null, no nodes are expanded.
  final int? initialExpandedLevels;

  final ValueNotifier<bool> isAllSelected = ValueNotifier<bool>(false);
  late bool isAllExpanded;

  TreeViewController(this.roots,
      {this.showSelectAll = false,
      this.showExpandCollapseButton = false,
      this.onSelectionChanged,
      this.initialExpandedLevels}) {
    isAllExpanded = initialExpandedLevels == 0;
    _init();
  }

  void _init() {
    _initializeNodes(roots, null);
    _setInitialExpansion(roots, 0);
    _updateAllNodesSelectionState();
    _updateSelectAllState();
  }

  /// Filters the tree nodes based on the provided filter function.
  ///
  /// The [filterFunction] should return true for nodes that should be visible.
  void filter(bool Function(ExplorableNode) filterFunction) {
    _applyFilter(roots, filterFunction);
    _updateAllNodesSelectionState();
    _updateSelectAllState();
  }

  /// Sorts the tree nodes based on the provided compare function.
  ///
  /// If [compareFunction] is null, the original order is restored.
  void sort(int Function(ExplorableNode, ExplorableNode)? compareFunction) {
    if (compareFunction == null) {
      _applySort(roots, (a, b) => a.originalIndex.compareTo(b.originalIndex));
    } else {
      _applySort(roots, compareFunction);
    }
  }

  /// Sets the selection state of all nodes.
  void setSelectAll(bool isSelected) {
    _setAllNodesSelection(isSelected);
    _updateSelectAllState();
    _notifySelectionChanged();
  }

  /// Expands all nodes in the tree.
  void expandAll() {
    _setExpansionState(roots, true);
  }

  /// Collapses all nodes in the tree.
  void collapseAll() {
    _setExpansionState(roots, false);
  }

  /// Sets the selected values in the tree.
  void setSelectedValues(List selectedValues) {
    for (var root in roots) {
      _setNodeAndDescendantsSelectionByValue(root, selectedValues);
    }
    _updateSelectAllState();
    _notifySelectionChanged();
  }

  void _setNodeAndDescendantsSelectionByValue(
      ExplorableNode node, List selectedValues) {
    if (node.hidden.value) return;
    node.isSelected.value = selectedValues.contains(node.value);
    node.isPartiallySelected.value = false;
    for (var child in node.children.value) {
      _setNodeAndDescendantsSelectionByValue(child, selectedValues);
    }
  }

  /// Returns a list of all selected nodes in the tree.
  List<ExplorableNode> getSelectedNodes() {
    return _getSelectedNodesRecursive(roots);
  }

  /// Returns a list of all selected child nodes of the given node.
  List<ExplorableNode> getChildSelectedNodes(ExplorableNode node) {
    return _getSelectedNodesRecursive(node.children.value);
  }

  /// Returns a list of all selected values in the tree.
  List<Explorable?> getSelectedValues() {
    return _getSelectedValues(roots);
  }

  /// Returns a list of all selected child nodes values of the given node.
  List<Explorable?> getChildSelectedValues(ExplorableNode node) {
    return _getSelectedValues(node.children.value);
  }

  void _initializeNodes(List<ExplorableNode> nodes, ExplorableNode? parent) {
    for (int i = 0; i < nodes.length; i++) {
      nodes[i].originalIndex = i;
      nodes[i].parent = parent;
      _initializeNodes(nodes[i].children.value, nodes[i]);
    }
  }

  void _setInitialExpansion(List<ExplorableNode> nodes, int currentLevel) {
    if (initialExpandedLevels == null) {
      return;
    }
    for (var node in nodes) {
      if (initialExpandedLevels == 0) {
        node.isExpanded.value = true;
      } else {
        node.isExpanded.value = currentLevel < initialExpandedLevels!;
      }
      if (node.isExpanded.value) {
        _setInitialExpansion(node.children.value, currentLevel + 1);
      }
    }
  }

  void _applySort(List<ExplorableNode> nodes,
      int Function(ExplorableNode, ExplorableNode) compareFunction) {
    nodes.sort(compareFunction);
    for (var node in nodes) {
      if (node.children.value.isNotEmpty) {
        _applySort(node.children.value, compareFunction);
      }
    }
  }

  void _applyFilter(List<ExplorableNode> nodes,
      bool Function(ExplorableNode) filterFunction) {
    for (var node in nodes) {
      bool shouldShow =
          filterFunction(node) || _hasVisibleDescendant(node, filterFunction);
      node.hidden.value = !shouldShow;
      _applyFilter(node.children.value, filterFunction);
    }
  }

  void _updateAllNodesSelectionState() {
    for (var root in roots) {
      _updateNodeSelectionStateBottomUp(root);
    }
  }

  void _updateNodeSelectionStateBottomUp(ExplorableNode node) {
    for (var child in node.children.value) {
      _updateNodeSelectionStateBottomUp(child);
    }
    _updateSingleNodeSelectionState(node);
  }

  void updateNodeSelection(ExplorableNode node, bool? isSelected) {
    if (isSelected == null) {
      _handlePartialSelection(node);
    } else {
      _updateNodeAndDescendants(node, isSelected);
    }
    _updateAncestorsRecursively(node);
    _updateSelectAllState();
    _notifySelectionChanged();
  }

  void _handlePartialSelection(ExplorableNode node) {
    if (node.isSelected.value || node.isPartiallySelected.value) {
      _updateNodeAndDescendants(node, false);
    } else {
      _updateNodeAndDescendants(node, true);
    }
  }

  void _updateNodeAndDescendants(ExplorableNode node, bool isSelected) {
    if (!node.hidden.value) {
      node.isSelected.value = isSelected;
      node.isPartiallySelected.value = false;
      for (var child in node.children.value) {
        _updateNodeAndDescendants(child, isSelected);
      }
    }
  }

  void _updateAncestorsRecursively(ExplorableNode node) {
    ExplorableNode? parent = node.parent;
    if (parent != null) {
      _updateSingleNodeSelectionState(parent);
      _updateAncestorsRecursively(parent);
    }
  }

  void _notifySelectionChanged() {
    List<Explorable?> selectedValues = _getSelectedValues(roots);
    onSelectionChanged?.call(selectedValues);
  }

  List<Explorable?> _getSelectedValues(List<ExplorableNode> nodes) {
    List<Explorable?> selectedValues = [];
    for (var node in nodes) {
      if (node.isSelected.value && !node.hidden.value) {
        selectedValues.add(node.value);
      }
      selectedValues.addAll(_getSelectedValues(node.children.value));
    }
    return selectedValues;
  }

  bool _hasVisibleDescendant(
      ExplorableNode node, bool Function(ExplorableNode) filterFunction) {
    for (var child in node.children.value) {
      if (filterFunction(child) ||
          _hasVisibleDescendant(child, filterFunction)) {
        return true;
      }
    }
    return false;
  }

  void _updateSingleNodeSelectionState(ExplorableNode node) {
    if (node.children.value.isEmpty ||
        node.children.value.every((child) => child.hidden.value)) {
      return;
    }

    List<ExplorableNode> visibleChildren =
        node.children.value.where((child) => !child.hidden.value).toList();
    bool allSelected = visibleChildren.every((child) => child.isSelected.value);
    bool anySelected = visibleChildren.any(
        (child) => child.isSelected.value || child.isPartiallySelected.value);

    if (allSelected) {
      node.isSelected.value = true;
      node.isPartiallySelected.value = false;
    } else if (anySelected) {
      node.isSelected.value = false;
      node.isPartiallySelected.value = true;
    } else {
      node.isSelected.value = false;
      node.isPartiallySelected.value = false;
    }
  }

  void _setExpansionState(List<ExplorableNode> nodes, bool isExpanded) {
    for (var node in nodes) {
      node.isExpanded.value = isExpanded;
      _setExpansionState(node.children.value, isExpanded);
    }
  }

  void _updateSelectAllState() {
    if (!showSelectAll) return;
    bool allSelected = roots
        .where((node) => !node.hidden.value)
        .every((node) => _isNodeFullySelected(node));
    isAllSelected.value = allSelected;
  }

  bool _isNodeFullySelected(ExplorableNode node) {
    if (node.hidden.value) return true;
    if (!node.isSelected.value) return false;
    return node.children.value
        .where((child) => !child.hidden.value)
        .every(_isNodeFullySelected);
  }

  void handleSelectAll(bool? value) {
    if (value == null) return;
    _setAllNodesSelection(value);
    _updateSelectAllState();
    _notifySelectionChanged();
  }

  void _setAllNodesSelection(bool isSelected) {
    for (var root in roots) {
      _setNodeAndDescendantsSelection(root, isSelected);
    }
  }

  void _setNodeAndDescendantsSelection(ExplorableNode node, bool isSelected) {
    if (node.hidden.value) return;
    node.isSelected.value = isSelected;
    node.isPartiallySelected.value = false;
    for (var child in node.children.value) {
      _setNodeAndDescendantsSelection(child, isSelected);
    }
  }

  void toggleExpandCollapseAll() {
    isAllExpanded = !isAllExpanded;
    _setExpansionState(roots, isAllExpanded);
  }

  List<ExplorableNode> _getSelectedNodesRecursive(List<ExplorableNode> nodes) {
    List<ExplorableNode> selectedNodes = [];
    for (var node in nodes) {
      if (node.isSelected.value && !node.hidden.value) {
        selectedNodes.add(node);
      }
      if (node.children.value.isNotEmpty) {
        selectedNodes.addAll(_getSelectedNodesRecursive(node.children.value));
      }
    }
    return selectedNodes;
  }

  void toggleNodeExpansion(ExplorableNode node) {
    node.isExpanded.value = !node.isExpanded.value;
  }
}

class TreeView extends StatelessWidget {
  final TreeViewController treeViewController;
  final ThemeData? theme;
  final void Function(ExplorableNode node, bool? isSelected)?
      updateNodeSelection;
  final void Function(ExplorableNode node)? toggleNodeExpansion;
  final void Function(ExplorableNode node)? onTap;
  final void Function(ExplorableNode node)? onDoubleTap;
  final void Function(ExplorableNode node)? onLongPress;

  const TreeView({
    super.key,
    required this.treeViewController,
    this.theme,
    this.updateNodeSelection,
    this.toggleNodeExpansion,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  /// 构建树的每个节点的头的展开和搜索按钮
  Widget _buildExpandCollapseButton(ExplorableNode node) {
    return ListenableBuilder(
        listenable: Listenable.merge([node.canBeExpanded, node.isExpanded]),
        builder: (context, _) {
          return SizedBox(
            width: 24,
            child: node.canBeExpanded.value
                ? IconButton(
                    icon: Icon(
                      node.isExpanded.value
                          ? Icons.expand_more
                          : Icons.chevron_right,
                    ),
                    onPressed: () {
                      treeViewController.toggleNodeExpansion(node);
                      toggleNodeExpansion?.call(node);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          );
        });
  }

  /// 构建树的每个节点的头的选择框按钮
  Widget _buildCheckboxButton(ExplorableNode node) {
    return ListenableBuilder(
        listenable:
            Listenable.merge([node.isSelected, node.isPartiallySelected]),
        builder: (context, _) {
          return SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: node.isSelected.value
                  ? true
                  : (node.isPartiallySelected.value ? null : false),
              tristate: true,
              onChanged: (bool? value) {
                treeViewController.updateNodeSelection(node, value ?? false);
                updateNodeSelection?.call(node, value ?? false);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        });
  }

  /// 构建树的每个节点的头的文本
  Widget _buildTextWidget(ExplorableNode node) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          node.value.name,
          style: TextStyle(
              fontWeight:
                  node.isCurrent.value ? FontWeight.w400 : FontWeight.normal),
        ),
      ],
    );
  }

  /// 构建树的每个节点的子树
  Widget _buildChildrenTreeNode(ExplorableNode node) {
    return ListenableBuilder(
        listenable: Listenable.merge([node.isExpanded, node.children]),
        builder: (context, _) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: node.isExpanded.value ? 0 : 1,
              end: node.isExpanded.value ? 1 : 0,
            ),
            builder: (context, value, child) {
              return ClipRect(
                child: Align(
                  heightFactor: value,
                  child: child,
                ),
              );
            },
            child: node.children.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: node.children.value
                          .map((child) => _buildTreeNode(child))
                          .toList(),
                    ),
                  )
                : null,
          );
        });
  }

  /// 构建树的每个节点的头
  Widget _buildTreeNodeHead(ExplorableNode node) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          onTap?.call(node);
        },
        onDoubleTap: () {
          onDoubleTap?.call(node);
        },
        onLongPress: () {
          onLongPress?.call(node);
        },
        child: Row(
          children: [
            _buildExpandCollapseButton(node),
            // _buildCheckboxButton(node),
            const SizedBox(width: 4),
            if (node.icon != null) node.icon!,
            const SizedBox(width: 4),
            Expanded(child: _buildTextWidget(node)),
          ],
        ),
      ),
    );
  }

  /// 构建一个节点及其所有子节点
  Widget _buildTreeNode(ExplorableNode node, {double leftPadding = 0}) {
    return ValueListenableBuilder(
        valueListenable: node.hidden,
        builder: (context, value, _) {
          if (node.hidden.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(left: leftPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                _buildTreeNodeHead(node),
                _buildChildrenTreeNode(node),
              ],
            ),
          );
        });
  }

  /// 构建选择所有和去选择所有的扩展和收缩按钮，显示在树的上边
  Widget _buildSelectAllExpandCollapseButton() {
    return treeViewController.showExpandCollapseButton
        ? IconButton(
            icon: Icon(treeViewController.isAllExpanded
                ? Icons.unfold_less
                : Icons.unfold_more),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: treeViewController.toggleExpandCollapseAll,
          )
        : const SizedBox();
  }

  /// 构建选择框按钮
  Widget _buildSelectAllCheckbox() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: treeViewController.isAllSelected.value,
        onChanged: treeViewController.handleSelectAll,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// "Select all"的按钮行
  Widget _buildSelectAllButton() {
    List<Widget> children = [];
    if (treeViewController.showSelectAll) {
      children.add(_buildSelectAllCheckbox());
    }
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: _buildSelectAllExpandCollapseButton(),
        ),
        ...children
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final verticalController = ScrollController();
    final horizontalController = ScrollController();
    List<Widget> children = [];
    if (treeViewController.showSelectAll ||
        treeViewController.showExpandCollapseButton) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              if (treeViewController.showSelectAll) {
                treeViewController.isAllSelected.value =
                    !treeViewController.isAllSelected.value;
                treeViewController
                    .handleSelectAll(treeViewController.isAllSelected.value);
              }
            },
            child: _buildSelectAllButton(),
          ),
        ),
      ));
    }
    for (var root in treeViewController.roots) {
      children.add(_buildTreeNode(root));
    }

    return Theme(
        data: theme ?? Theme.of(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              controller: horizontalController,
              child: Scrollbar(
                controller: verticalController,
                notificationPredicate: (notification) =>
                    notification.depth >= 0,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: verticalController,
                    scrollDirection: Axis.vertical,
                    child: IntrinsicWidth(
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ));
  }
}
