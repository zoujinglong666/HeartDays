import 'package:flutter/material.dart';

class ReorderableColumn extends StatefulWidget {
  final List<Widget> children;
  final Function(int, int) onReorder;
  final bool needsLongPressDraggable;
  final EdgeInsets padding;

  const ReorderableColumn({
    Key? key,
    required this.children,
    required this.onReorder,
    this.needsLongPressDraggable = true,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

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
      buildDefaultDragHandles: widget.needsLongPressDraggable,
      onReorder: widget.onReorder,
      scrollController: _scrollController,
      children: widget.children,
    );
  }
}