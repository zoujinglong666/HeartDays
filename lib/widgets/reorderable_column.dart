import 'package:flutter/material.dart';

class ReorderableColumn extends StatefulWidget {
  final List<Widget> children;
  final Function(int, int) onReorder;
  final bool needsLongPressDraggable;
  final EdgeInsets padding;

  const ReorderableColumn({
    super.key,
    required this.children,
    required this.onReorder,
    this.needsLongPressDraggable = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<ReorderableColumn> createState() => _ReorderableColumnState();
}

class _ReorderableColumnState extends State<ReorderableColumn> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: widget.padding,
      onReorder: widget.onReorder,
      scrollController: _scrollController,
      buildDefaultDragHandles: false, // 关闭默认拖拽手柄

      children: List.generate(widget.children.length, (index) {
        final child = widget.children[index];

        return Container(
          key: ValueKey(index),
          // 用 GestureDetector 包裹一层，可以根据需要实现更多自定义交互
          child: widget.needsLongPressDraggable
              ? ReorderableDelayedDragStartListener(
            index: index,
            child: child,
          )
              : ReorderableDragStartListener(
            index: index,
            child: child,
          ),
        );
      }),
    );
  }
}
