import 'package:flutter/material.dart';

typedef PickerLabelBuilder<T> = String Function(T value);
typedef PickerColumnsBuilder<T> = List<List<T>> Function(List<T> selected);

class AppMultiPicker {
  static void show<T>({
    required BuildContext context,
    required List<List<T>> columns,
    required void Function(List<T>) onConfirm,
    String title = '请选择',
    PickerLabelBuilder<T>? labelBuilder,
    PickerColumnsBuilder<T>? onColumnChanged, // 支持联动
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return _MultiPickerSheet<T>(
          title: title,
          columns: columns,
          labelBuilder: labelBuilder,
          onConfirm: onConfirm,
          onColumnChanged: onColumnChanged,
        );
      },
    );
  }
}

class _MultiPickerSheet<T> extends StatefulWidget {
  final List<List<T>> columns;
  final PickerLabelBuilder<T>? labelBuilder;
  final PickerColumnsBuilder<T>? onColumnChanged;
  final void Function(List<T>) onConfirm;
  final String title;

  const _MultiPickerSheet({
    required this.columns,
    required this.onConfirm,
    this.labelBuilder,
    this.onColumnChanged,
    required this.title,
  });

  @override
  State<_MultiPickerSheet<T>> createState() => _MultiPickerSheetState<T>();
}

class _MultiPickerSheetState<T> extends State<_MultiPickerSheet<T>> {
  late List<List<T>> _columns;
  late List<int> _selectedIndexes;

  final List<FixedExtentScrollController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _columns = widget.columns;
    _selectedIndexes = List.generate(_columns.length, (_) => 0);
    _controllers.addAll(
      _columns
          .asMap()
          .map((i, col) => MapEntry(i,
          FixedExtentScrollController(initialItem: _selectedIndexes[i])))
          .values
          .toList(),
    );
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  List<T> get _selectedValues => List.generate(
    _columns.length,
        (i) => _columns[i][_selectedIndexes[i]],
  );

  void _onConfirm() {
    widget.onConfirm(_selectedValues);
    Navigator.of(context).pop();
  }

  void _onColumnChangedInternal(int columnIndex, int selectedIndex) {
    setState(() {
      _selectedIndexes[columnIndex] = selectedIndex;

      // 如果支持联动，刷新后续列
      if (widget.onColumnChanged != null) {
        final newColumns = widget.onColumnChanged!(_selectedValues);
        _columns = newColumns;

        // 修正选中索引
        for (int i = columnIndex + 1; i < _columns.length; i++) {
          _selectedIndexes[i] = 0;
          _controllers[i].jumpToItem(0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const itemHeight = 42.0;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onConfirm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            color: Color(0xFF3482ff),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
            SizedBox(
              height: itemHeight * 5,
              child: Stack(
                children: [
                  // 滚轮内容
                  Row(
                    children: List.generate(_columns.length, (colIndex) {
                      return Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _controllers[colIndex],
                          itemExtent: itemHeight,
                          diameterRatio: 100, // 极大值，近似平面
                          perspective: 0.001, // 非常小，近似无透视
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            _onColumnChangedInternal(colIndex, index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= _columns[colIndex].length) return null;
                              final value = _columns[colIndex][index];
                              final label = widget.labelBuilder?.call(value) ?? value.toString();
                              final isSelected = index == _selectedIndexes[colIndex];
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.ease,
                                alignment: Alignment.center,
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color: Colors.transparent, // 或更浅的灰色
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : null,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: isSelected ? 18 : 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF3482ff) : const Color(0xFF999999),
                                  ),
                                ),
                              );
                            },
                            childCount: _columns[colIndex].length,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
