import 'package:flutter/material.dart';

class DraggableList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final void Function(List<T>)? onReorderFinished;

  const DraggableList({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.onReorderFinished,
  }) : super(key: key);

  @override
  State<DraggableList<T>> createState() => _DraggableListState<T>();
}

class _DraggableListState<T> extends State<DraggableList<T>> {
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List<T>.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant DraggableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = List<T>.from(widget.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
        if (widget.onReorderFinished != null) {
          widget.onReorderFinished!(_items);
        }
      },
      children: List.generate(_items.length, (index) {
        return KeyedSubtree(
          key: ValueKey(_items[index]),
          child: widget.itemBuilder(context, _items[index], index),
        );
      }),
    );
  }
}